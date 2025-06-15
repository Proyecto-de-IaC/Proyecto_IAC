const { DynamoDBClient, PutItemCommand } = require('@aws-sdk/client-dynamodb');
const { v4: uuidv4 } = require('uuid');
const winston = require('winston');

const client = new DynamoDBClient();
const TABLE_NAME = process.env.REGISTRATIONS_TABLE;
const LOG_LEVEL = process.env.LOG_LEVEL || 'info';

const logger = winston.createLogger({
  level: LOG_LEVEL.toLowerCase(),
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [new winston.transports.Console()]
});

exports.handler = async (event) => {
  logger.debug('Event received', { event });

  let body;
  try {
    body = JSON.parse(event.body || '{}');
  } catch (parseError) {
    logger.error('Error parsing event body', { error: parseError.message });
    return {
      statusCode: 400,
      body: JSON.stringify({ error: 'Invalid JSON in request body' })
    };
  }

  const registration = {
    id: { S: uuidv4() }, // ID único con UUID v4
    user_email: { S: body.user_email || 'no-email@example.com' },
    course_id: { S: body.course_id || 'unknown-course' },
    timestamp: { S: new Date().toISOString() }
  };

  const command = new PutItemCommand({
    TableName: TABLE_NAME,
    Item: registration
  });

  try {
    await client.send(command);
    logger.info('Registration saved', { registration });
    return {
      statusCode: 201,
      body: JSON.stringify({ message: 'Registration saved', registration })
    };
  } catch (err) {
    logger.error('DynamoDB error', { error: err.message, stack: err.stack });
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Could not save registration' })
    };
  }
};
