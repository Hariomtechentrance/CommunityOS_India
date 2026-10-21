import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { PrismaService } from '../prisma/prisma.service';

/**
 * Catches every exception NestJS would otherwise handle, logs it to
 * ErrorLog (fire-and-forget - a logging failure must never affect the
 * actual error response), and re-produces the exact same response NestJS's
 * own default filter would have sent. This is purely additive observability,
 * not a behavior change for API consumers.
 */
@Catch()
export class ErrorLogFilter implements ExceptionFilter {
  private readonly logger = new Logger(ErrorLogFilter.name);

  constructor(private readonly prisma: PrismaService) {}

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request & { user?: { userId?: string } }>();

    const isHttpException = exception instanceof HttpException;
    const statusCode = isHttpException
      ? exception.getStatus()
      : HttpStatus.INTERNAL_SERVER_ERROR;
    const message = isHttpException
      ? JSON.stringify(exception.getResponse())
      : exception instanceof Error
        ? exception.message
        : 'Unknown error';

    // Webhook/health-check noise and expected 4xx validation errors aren't
    // useful signal for "is this feature broken" - only 5xx (genuine bugs)
    // get logged, so the admin panel's error counts mean something.
    if (statusCode >= 500) {
      this.prisma.errorLog
        .create({
          data: {
            method: request.method,
            path: request.originalUrl ?? request.url,
            statusCode,
            message: message.slice(0, 2000),
            userId: request.user?.userId,
          },
        })
        .catch((e) => this.logger.warn(`Failed to write ErrorLog: ${e}`));
    }

    if (isHttpException) {
      response.status(statusCode).json(exception.getResponse());
    } else {
      this.logger.error(exception);
      response.status(statusCode).json({
        statusCode,
        message: 'Internal server error',
      });
    }
  }
}
