-- CreateTable
CREATE TABLE "GoalCommunity" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "category" TEXT,
    "durationDays" INTEGER NOT NULL,
    "createdById" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "GoalCommunity_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "GoalCommunityMember" (
    "id" TEXT NOT NULL,
    "goalCommunityId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "currentStreak" INTEGER NOT NULL DEFAULT 0,
    "longestStreak" INTEGER NOT NULL DEFAULT 0,
    "lastCheckInDate" TIMESTAMP(3),

    CONSTRAINT "GoalCommunityMember_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "GoalCheckIn" (
    "id" TEXT NOT NULL,
    "goalCommunityMemberId" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "GoalCheckIn_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "GoalCommunity_category_idx" ON "GoalCommunity"("category");

-- CreateIndex
CREATE INDEX "GoalCommunityMember_goalCommunityId_idx" ON "GoalCommunityMember"("goalCommunityId");

-- CreateIndex
CREATE UNIQUE INDEX "GoalCommunityMember_goalCommunityId_userId_key" ON "GoalCommunityMember"("goalCommunityId", "userId");

-- CreateIndex
CREATE UNIQUE INDEX "GoalCheckIn_goalCommunityMemberId_date_key" ON "GoalCheckIn"("goalCommunityMemberId", "date");

-- AddForeignKey
ALTER TABLE "GoalCommunity" ADD CONSTRAINT "GoalCommunity_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GoalCommunityMember" ADD CONSTRAINT "GoalCommunityMember_goalCommunityId_fkey" FOREIGN KEY ("goalCommunityId") REFERENCES "GoalCommunity"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GoalCommunityMember" ADD CONSTRAINT "GoalCommunityMember_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GoalCheckIn" ADD CONSTRAINT "GoalCheckIn_goalCommunityMemberId_fkey" FOREIGN KEY ("goalCommunityMemberId") REFERENCES "GoalCommunityMember"("id") ON DELETE CASCADE ON UPDATE CASCADE;
