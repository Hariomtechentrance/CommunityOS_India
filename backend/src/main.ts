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

  // Render's free tier spins the service down after 15 minutes of no
  // inbound HTTP traffic, causing a ~30s cold start for the next visitor.
  // Pinging ourselves from inside the running process every 14 minutes
  // keeps traffic flowing so it never goes idle long enough to sleep.
  // RENDER_EXTERNAL_URL is auto-injected by Render only in deployed
  // environments, so this is a no-op locally. More reliable than an
  // external scheduler (e.g. GitHub Actions cron), which can be silently
  // throttled to roughly hourly under load instead of the configured
  // interval.
  const selfUrl = process.env.RENDER_EXTERNAL_URL;
  if (selfUrl) {
    setInterval(() => {
      fetch(selfUrl).catch(() => {});
    }, 14 * 60 * 1000);
  }
}
bootstrap();
