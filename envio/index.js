const AWS = require('aws-sdk');
const winston = require('winston');

const ses = new AWS.SES();
const sqs = new AWS.SQS();

const FROM_EMAIL = process.env.SES_EMAIL_IDENTITY;
const LOG_LEVEL = process.env.LOG_LEVEL || 'info';
const QUEUE_URL = process.env.SQS_QUEUE_URL;

const logger = winston.createLogger({
  level: LOG_LEVEL,
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [new winston.transports.Console()]
});

exports.handler = async () => {
  logger.info('Lambda Send Email iniciada');

  try {
    // Recibe mensajes desde SQS
    const sqsResponse = await sqs.receiveMessage({
      QueueUrl: QUEUE_URL,
      MaxNumberOfMessages: 10,
      WaitTimeSeconds: 5
    }).promise();

    if (!sqsResponse.Messages || sqsResponse.Messages.length === 0) {
      logger.info('No hay mensajes en la cola');
      return;
    }

    for (const message of sqsResponse.Messages) {
      logger.debug('Mensaje recibido de SQS', { message });

      const body = JSON.parse(message.Body);
      const { to, subject, bodyText, bodyHtml } = body;

      if (!to || !subject || (!bodyText && !bodyHtml)) {
        logger.warn('Mensaje incompleto. Falta "to", "subject" o contenido.');
        continue;
      }

      const params = {
        Destination: { ToAddresses: [to] },
        Message: {
          Body: {},
          Subject: { Data: subject }
        },
        Source: FROM_EMAIL
      };

      if (bodyHtml) {
        params.Message.Body.Html = { Data: bodyHtml };
      }
      if (bodyText) {
        params.Message.Body.Text = { Data: bodyText };
      }

      // Envía el correo
      await ses.sendEmail(params).promise();
      logger.info('Correo enviado con éxito a', { to });

      // Elimina mensaje de la cola
      await sqs.deleteMessage({
        QueueUrl: QUEUE_URL,
        ReceiptHandle: message.ReceiptHandle
      }).promise();
    }

  } catch (error) {
    logger.error('Error en send_email handler', {
      message: error.message,
      stack: error.stack
    });
    throw error;
  }
};
