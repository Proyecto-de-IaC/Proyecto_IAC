const AWS = require('aws-sdk');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const winston = require('winston');

// Configuración del logger Winston
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [new winston.transports.Console()]
});

const dynamodb = new AWS.DynamoDB.DocumentClient();
const sqs = new AWS.SQS();

const PURCHASES_TABLE = process.env.PURCHASES_TABLE;
const COURSES_TABLE = process.env.COURSES_TABLE;
const EMAIL_QUEUE_URL = process.env.EMAIL_QUEUE_URL;

exports.handler = async (event, context) => {
  logger.debug('Evento recibido en purchase-course', { event });

  try {
    const { courseId, userId, paymentMethodId } = JSON.parse(event.body);

    if (!courseId || !userId || !paymentMethodId) {
      logger.warn('Parámetros faltantes en la petición', { courseId, userId, paymentMethodId });
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Missing required parameters' }),
      };
    }

    // Obtener info del curso
    const courseData = await dynamodb.get({
      TableName: COURSES_TABLE,
      Key: { id: courseId },
    }).promise();

    if (!courseData.Item) {
      logger.warn('Curso no encontrado', { courseId });
      return {
        statusCode: 404,
        body: JSON.stringify({ message: 'Course not found' }),
      };
    }

    const course = courseData.Item;
    logger.debug('Datos del curso obtenidos', { course });

    // Crear pago con Stripe
    const paymentIntent = await stripe.paymentIntents.create({
      amount: course.price_cents,
      currency: 'usd',
      payment_method: paymentMethodId,
      confirm: true,
      metadata: { courseId, userId }
    });

    logger.info('Pago realizado con éxito', { paymentIntentId: paymentIntent.id });

    // Guardar compra en DynamoDB
    const purchaseRecord = {
      id: `${userId}-${courseId}-${Date.now()}`,
      userId,
      courseId,
      purchaseDate: new Date().toISOString(),
      paymentIntentId: paymentIntent.id,
      status: 'COMPLETED',
    };

    await dynamodb.put({
      TableName: PURCHASES_TABLE,
      Item: purchaseRecord,
    }).promise();

    logger.info('Compra registrada', { purchaseId: purchaseRecord.id });

    // Enviar mensaje a SQS para notificación
    const messageBody = JSON.stringify({
      userId,
      courseId,
      purchaseId: purchaseRecord.id,
    });

    await sqs.sendMessage({
      QueueUrl: EMAIL_QUEUE_URL,
      MessageBody: messageBody,
    }).promise();

    logger.info('Mensaje enviado a la cola SQS', { messageBody });

    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Purchase completed successfully' }),
    };

  } catch (error) {
    logger.error('Error procesando la compra', {
      message: error.message,
      stack: error.stack,
      event,
    });

    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Internal server error', error: error.message }),
    };
  }
};
