-- CreateTable
CREATE TABLE "AreaPostReaction" (
    "id" TEXT NOT NULL,
    "areaPostId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "emoji" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AreaPostReaction_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "AreaPostReaction_areaPostId_idx" ON "AreaPostReaction"("areaPostId");

-- CreateIndex
CREATE UNIQUE INDEX "AreaPostReaction_areaPostId_userId_key" ON "AreaPostReaction"("areaPostId", "userId");

-- AddForeignKey
ALTER TABLE "AreaPostReaction" ADD CONSTRAINT "AreaPostReaction_areaPostId_fkey" FOREIGN KEY ("areaPostId") REFERENCES "AreaPost"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AreaPostReaction" ADD CONSTRAINT "AreaPostReaction_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
