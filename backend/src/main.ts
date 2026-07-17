import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { corsOptions } from './common/socket-cors';

async function bootstrap() {
  // rawBody: true - the Razorpay webhook needs the exact raw request bytes
  // to verify its HMAC signature; a re-serialized JSON body would produce a
  // different signature and always fail verification.
  const app = await NestFactory.create(AppModule, { rawBody: true });

  app.use(helmet());
  // Restricted via CORS_ALLOWED_ORIGINS in production; allows any origin
  // only when that env var is unset (local dev). See common/socket-cors.ts -
  // native Android/iOS clients aren't affected by this either way.
  app.enableCors(corsOptions);
  app.useWebSocketAdapter(new IoAdapter(app));

  app.useGlobalPipes(
    new ValidationPipe({ whitelist: true, transform: true, forbidNonWhitelisted: true }),
  );

  const config = new DocumentBuilder()
    .setTitle('NIKAT API')
    .setDescription('Backend & admin core for the NIKAT MVP')
    .setVersion('0.1')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
