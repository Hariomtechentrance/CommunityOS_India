import { SetMetadata } from '@nestjs/common';
import { MembershipRole } from '../common/roles.enum';

export const ROLES_KEY = 'societyRoles';
export const Roles = (...roles: MembershipRole[]) => SetMetadata(ROLES_KEY, roles);
