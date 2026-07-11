-- AlterTable
ALTER TABLE "AreaPost" ADD COLUMN     "activityTime" TEXT,
ADD COLUMN     "businessHours" TEXT,
ADD COLUMN     "partnersNeeded" INTEGER;

-- CreateTable
CREATE TABLE "AreaPostSave" (
    "id" TEXT NOT NULL,
    "areaPostId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AreaPostSave_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AreaPostComment" (
    "id" TEXT NOT NULL,
    "areaPostId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AreaPostComment_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "AreaPostSave_areaPostId_userId_key" ON "AreaPostSave"("areaPostId", "userId");

-- CreateIndex
CREATE INDEX "AreaPostComment_areaPostId_idx" ON "AreaPostComment"("areaPostId");

-- AddForeignKey
ALTER TABLE "AreaPostSave" ADD CONSTRAINT "AreaPostSave_areaPostId_fkey" FOREIGN KEY ("areaPostId") REFERENCES "AreaPost"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AreaPostSave" ADD CONSTRAINT "AreaPostSave_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AreaPostComment" ADD CONSTRAINT "AreaPostComment_areaPostId_fkey" FOREIGN KEY ("areaPostId") REFERENCES "AreaPost"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AreaPostComment" ADD CONSTRAINT "AreaPostComment_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
