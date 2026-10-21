import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SocietiesService } from '../societies/societies.service';
import { UsersService } from '../users/users.service';

@Injectable()
export class SearchService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly users: UsersService,
    private readonly societies: SocietiesService,
  ) {}

  /** One search box across people, communities, area posts and goal
   * communities. Area posts are scoped to the viewer's own area (a simple
   * text match + area filter, not AreaService's full geo-visibility engine)
   * - good enough for "find things mentioning X near me" without
   * reimplementing the whole reach/radius logic here. Marketplace listings
   * and society Events are deliberately excluded - both are private to a
   * specific society's members, and a global search shouldn't leak them
   * across societies. */
  async searchAll(query: string, viewerUserId: string, viewerArea: string | null | undefined) {
    const q = query.trim();
    if (!q) return { users: [], communities: [], posts: [], goalCommunities: [] };

    const [users, communities, posts, goalCommunities] = await Promise.all([
      this.users.searchUsers(q, viewerUserId),
      this.societies.search(q),
      this.prisma.areaPost.findMany({
        where: {
          OR: [
            { title: { contains: q, mode: 'insensitive' } },
            { description: { contains: q, mode: 'insensitive' } },
          ],
          ...(viewerArea ? { area: { equals: viewerArea, mode: 'insensitive' } } : {}),
        },
        include: { user: { select: { id: true, name: true, avatarUrl: true } } },
        orderBy: { createdAt: 'desc' },
        take: 15,
      }),
      this.prisma.goalCommunity.findMany({
        where: {
          OR: [
            { title: { contains: q, mode: 'insensitive' } },
            { description: { contains: q, mode: 'insensitive' } },
          ],
        },
        take: 15,
      }),
    ]);

    return { users, communities, posts, goalCommunities };
  }
}
