const { DynamoDBClient, GetItemCommand, PutItemCommand, UpdateItemCommand } = require('@aws-sdk/client-dynamodb');
const { SQSClient, SendMessageCommand } = require('@aws-sdk/client-sqs');
const winston = require('winston');

const REGION = process.env.AWS_REGION || 'us-east-1';
const PROGRESS_TABLE = process.env.PROGRESS_TABLE;
const COURSES_TABLE = process.env.COURSES_TABLE;
const CERTIFICATES_QUEUE_URL = process.env.CERTIFICATES_QUEUE;
const LOG_LEVEL = process.env.LOG_LEVEL || 'info';

const logger = winston.createLogger({
  level: LOG_LEVEL.toLowerCase(),
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [new winston.transports.Console()]
});

const dynamoClient = new DynamoDBClient({ region: REGION });
const sqsClient = new SQSClient({ region: REGION });

exports.handler = async (event) => {
  logger.debug('Event received', { event });

  let body;
  try {
    body = JSON.parse(event.body || '{}');
  } catch (error) {
    logger.error('Invalid JSON body', { error: error.message });
    return {
      statusCode: 400,
      body: JSON.stringify({ error: 'Invalid JSON in request body' })
    };
  }

  const { user_id, course_id, progress } = body;
  if (!user_id || !course_id || progress === undefined) {
    logger.error('Missing required fields', { body });
    return {
      statusCode: 400,
      body: JSON.stringify({ error: 'user_id, course_id and progress are required' })
    };
  }

  // Actualizar progreso en DynamoDB
  const updateParams = {
    TableName: PROGRESS_TABLE,
    Key: {
      user_id: { S: user_id },
      course_id: { S: course_id }
    },
    UpdateExpression: 'SET progress = :progress, updated_at = :now',
    ExpressionAttributeValues: {
      ':progress': { N: progress.toString() },
      ':now': { S: new Date().toISOString() }
    }
  };

  try {
    await dynamoClient.send(new UpdateItemCommand(updateParams));
    logger.info('Progress updated', { user_id, course_id, progress });
  } catch (err) {
    logger.error('Error updating progress', { error: err.message });
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Failed to update progress' })
    };
  }

  // Si el progreso es 100%, enviar mensaje a la cola de certificados
  if (progress === 100) {
    const messageBody = JSON.stringify({ user_id, course_id, timestamp: new Date().toISOString() });
    const sqsParams = {
      QueueUrl: CERTIFICATES_QUEUE_URL,
      MessageBody: messageBody
    };

    try {
      await sqsClient.send(new SendMessageCommand(sqsParams));
      logger.info('Certificate request sent to SQS', { user_id, course_id });
    } catch (err) {
      logger.error('Failed to send certificate message to SQS', { error: err.message });
      // No se retorna error para que la función considere éxito si update fue ok
    }
  }

  return {
    statusCode: 200,
    body: JSON.stringify({ message: 'Progress tracked successfully' })
  };
};
