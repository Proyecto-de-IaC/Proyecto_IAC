const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');
const { DynamoDBClient, UpdateItemCommand } = require('@aws-sdk/client-dynamodb');
const winston = require('winston');

const REGION = process.env.AWS_REGION || 'us-east-2';
const VIDEOS_BUCKET = process.env.VIDEOS_BUCKET;
const COURSES_TABLE = process.env.COURSES_TABLE;
const LOG_LEVEL = process.env.LOG_LEVEL || 'info';
const MAX_FILE_SIZE = parseInt(process.env.MAX_FILE_SIZE, 10) || 10 * 1024 * 1024; // 100 MB por defecto

const s3Client = new S3Client({ region: REGION });
const dynamoClient = new DynamoDBClient({ region: REGION });

const logger = winston.createLogger({
  level: LOG_LEVEL.toLowerCase(),
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [new winston.transports.Console()]
});

exports.handler = async (event) => {
  logger.debug('Evento recibido', { event });
    if (!event.Records || !Array.isArray(event.Records)) {
      logger.warn('No se encontraron Records en el evento. Evento ignorado.');
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Evento inválido: no contiene Records' })
      };
    }

  // Evento típico S3: examinar cada registro
  for (const record of event.Records) {
    const bucketName = record.s3.bucket.name;
    const objectKey = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));
    const objectSize = record.s3.object.size;

    logger.info(`Archivo subido: ${objectKey} (${objectSize} bytes)`);

    if (bucketName !== VIDEOS_BUCKET) {
      logger.warn(`Evento recibido de bucket no esperado: ${bucketName}`);
      continue;
    }

    if (objectSize > MAX_FILE_SIZE) {
      logger.error(`Archivo excede tamaño máximo permitido: ${objectSize} bytes > ${MAX_FILE_SIZE} bytes`);
      
      continue;
    }

    // Actualizar metadata en DynamoDB (ejemplo: marcar video como subido)
    const params = {
      TableName: COURSES_TABLE,
      Key: { video_id: { S: objectKey } },
      UpdateExpression: 'SET upload_status = :status, updated_at = :now',
      ExpressionAttributeValues: {
        ':status': { S: 'uploaded' },
        ':now': { S: new Date().toISOString() }
      }
    };

    try {
      await dynamoClient.send(new UpdateItemCommand(params));
      logger.info('Estado de video actualizado en DynamoDB', { videoId: objectKey });
    } catch (err) {
      logger.error('Error actualizando DynamoDB', { error: err.message });
      // No interrumpir el procesamiento del evento
    }
  }

  return {
    statusCode: 200,
    body: JSON.stringify({ message: 'Eventos procesados' })
  };
};
