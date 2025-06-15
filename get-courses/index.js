const AWS = require('aws-sdk');
const winston = require('winston');

const dynamo = new AWS.DynamoDB.DocumentClient();

const COURSES_TABLE = process.env.COURSES_TABLE;
const PURCHASES_TABLE = process.env.PURCHASES_TABLE;
const COURSE_PROGRESS_TABLE = process.env.COURSE_PROGRESS_TABLE;
const LOG_LEVEL = process.env.LOG_LEVEL || 'info';

const logger = winston.createLogger({
  level: LOG_LEVEL,
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [new winston.transports.Console()]
});

exports.handler = async (event) => {
  logger.info("Obteniendo cursos disponibles", { event });

  const userId = event.queryStringParameters?.userId;

  if (!userId) {
    logger.warn("Parámetro 'userId' no proporcionado");
    return {
      statusCode: 400,
      body: JSON.stringify({ error: "Falta el parámetro 'userId'" })
    };
  }

  try {
    // 1. Obtener todos los cursos
    const coursesResult = await dynamo.scan({ TableName: COURSES_TABLE }).promise();
    const allCourses = coursesResult.Items || [];

    // 2. Obtener compras del usuario
    const purchasesResult = await dynamo.query({
      TableName: PURCHASES_TABLE,
      KeyConditionExpression: "userId = :u",
      ExpressionAttributeValues: { ":u": userId }
    }).promise();

    const purchasedCourseIds = purchasesResult.Items.map(item => item.courseId);

    // 3. Obtener progreso por curso
    const progressResult = await dynamo.query({
      TableName: COURSE_PROGRESS_TABLE,
      KeyConditionExpression: "userId = :u",
      ExpressionAttributeValues: { ":u": userId }
    }).promise();

    const progressByCourse = {};
    for (const item of progressResult.Items) {
      progressByCourse[item.courseId] = item.progress;
    }

    // 4. Armar respuesta con estado y progreso
    const userCourses = allCourses
      .filter(course => purchasedCourseIds.includes(course.courseId))
      .map(course => ({
        ...course,
        purchased: true,
        progress: progressByCourse[course.courseId] || 0
      }));

    return {
      statusCode: 200,
      body: JSON.stringify({ courses: userCourses })
    };

  } catch (error) {
    logger.error("Error al obtener los cursos", {
      message: error.message,
      stack: error.stack
    });

    return {
      statusCode: 500,
      body: JSON.stringify({ error: "Error interno del servidor" })
    };
  }
};
