const AWS = require('aws-sdk');
const winston = require('winston');

const dynamoDB = new AWS.DynamoDB.DocumentClient();
const sqs = new AWS.SQS();

const TABLE_NAME = process.env.CERTIFICATES_TABLE;
const SQS_QUEUE_URL = process.env.SQS_QUEUE_URL;

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [new winston.transports.Console()]
});

exports.handler = async (event) => {
  logger.debug('Evento recibido en certificates', { event });

  try {
    const { userId, courseId, progress } = event;

    if (progress < 100) {
      logger.warn('El usuario no ha completado el curso', { userId, courseId, progress });
      return { statusCode: 400, body: JSON.stringify({ error: 'Curso incompleto' }) };
    }

    const certificate = {
      id: `${userId}-${courseId}`,
      userId,
      courseId,
      issuedAt: new Date().toISOString()
    };

    // Guardar en DynamoDB
    await dynamoDB.put({
      TableName: TABLE_NAME,
      Item: certificate
    }).promise();

    logger.info('Certificado registrado en DynamoDB', certificate);

    // Enviar mensaje a SQS para que otra Lambda envíe el correo
    const message = {
      userId,
      courseId,
      email: event.email,
      certificateId: certificate.id
    };

    await sqs.sendMessage({
      QueueUrl: SQS_QUEUE_URL,
      MessageBody: JSON.stringify(message)
    }).promise();

    logger.info('Mensaje enviado a SQS para enviar correo', message);

    return {
      statusCode: 200,
      body: JSON.stringify({ status: 'success', certificateId: certificate.id })
    };

  } catch (error) {
    logger.error('Error generando certificado', {
      error: error.message,
      stack: error.stack,
      event
    });

    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Error generando certificado' })
    };
  }
};
