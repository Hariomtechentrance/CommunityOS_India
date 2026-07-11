import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PrismaService } from '../../prisma/prisma.service';
import { ROLES_KEY } from '../decorators/roles.decorator';
import { MembershipRole } from '../common/roles.enum';

/**
 * Requires a valid JwtAuthGuard to have already run (needs req.user).
 * Looks up the caller's APPROVED membership for the :societyId route param.
 * If @Roles(...) is set on the handler, the membership's role must be in that list;
 * otherwise any approved membership (any role) is sufficient.
 */
@Injectable()
export class SocietyRolesGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredRoles = this.reflector.getAllAndOverride<MembershipRole[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );

    const request = context.switchToHttp().getRequest();
    const societyId = request.params?.societyId;
    const userId = request.user?.userId;

    if (!societyId || !userId) {
      throw new ForbiddenException('Missing society or user context');
    }

    const membership = await this.prisma.membership.findUnique({
      where: { userId_societyId: { userId, societyId } },
    });

    if (!membership || membership.status !== 'APPROVED') {
      throw new ForbiddenException('Not an approved member of this society');
    }

    if (requiredRoles?.length && !requiredRoles.includes(membership.role)) {
      throw new ForbiddenException('Insufficient role for this action');
    }

    request.membership = membership;
    return true;
  }
}
