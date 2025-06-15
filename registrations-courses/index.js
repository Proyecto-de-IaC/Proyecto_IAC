const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');
const winston = require('winston');

const dynamoDb = new AWS.DynamoDB.DocumentClient();

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [new winston.transports.Console()]
});

exports.handler = async (event) => {
  logger.debug('Evento recibido', { event });

  try {
    const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
    const { userId, courseId } = body;

    if (!userId || !courseId) {
      logger.warn('Faltan parámetros obligatorios');
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'userId y courseId son obligatorios.' })
      };
    }

    const params = {
      TableName: process.env.COURSE_ENROLLMENTS_TABLE,
      Item: {
        userId,
        courseId,
        enrollmentDate: new Date().toISOString()
      },
      ConditionExpression: "attribute_not_exists(userId) AND attribute_not_exists(courseId)"
    };

    await dynamoDb.put(params).promise();

    logger.info('Inscripción exitosa', { userId, courseId });

    return {
      statusCode: 201,
      body: JSON.stringify({ message: 'Usuario inscrito correctamente.' })
    };

  } catch (error) {
    logger.error('Error al inscribir usuario', {
      message: error.message,
      stack: error.stack
    });
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Error interno al registrar inscripción.' })
    };
  }
};
