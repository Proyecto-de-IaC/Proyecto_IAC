const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');
const winston = require('winston');

const dynamoDB = new AWS.DynamoDB.DocumentClient();
const s3 = new AWS.S3();

const COURSES_TABLE = process.env.COURSES_TABLE;
const VIDEOS_BUCKET = process.env.VIDEOS_BUCKET;

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [new winston.transports.Console()]
});

exports.handler = async (event) => {
  logger.debug('Evento recibido en Create Course', { event });

  try {
    const { title, description, videoKey } = JSON.parse(event.body);

    if (!title || !description) {
      logger.warn('Faltan campos requeridos');
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'title y description son requeridos' })
      };
    }

    const courseId = uuidv4();
    const createdAt = new Date().toISOString();

    const newCourse = {
      courseId,
      title,
      description,
      videoKey: videoKey || null,
      createdAt
    };

    await dynamoDB.put({
      TableName: COURSES_TABLE,
      Item: newCourse
    }).promise();

    logger.info('Curso creado correctamente', { courseId, title });

    return {
      statusCode: 201,
      body: JSON.stringify({ message: 'Curso creado', courseId })
    };

  } catch (error) {
    logger.error('Error creando curso', {
      error: error.message,
      stack: error.stack
    });

    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Error interno del servidor' })
    };
  }
};
