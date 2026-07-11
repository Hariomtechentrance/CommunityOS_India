-- CreateEnum
CREATE TYPE "AreaPostKind" AS ENUM ('UPDATE', 'SHOP', 'SPORTS_INVITE');

-- CreateTable
CREATE TABLE "Profile" (
    "id" TEXT NOT NULL,
    "displayName" TEXT NOT NULL,
    "area" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Profile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AreaPost" (
    "id" TEXT NOT NULL,
    "profileId" TEXT NOT NULL,
    "area" TEXT NOT NULL,
    "kind" "AreaPostKind" NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "imageUrls" TEXT[],
    "location" TEXT,
    "sportName" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AreaPost_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AreaPostInterest" (
    "id" TEXT NOT NULL,
    "areaPostId" TEXT NOT NULL,
    "profileId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AreaPostInterest_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Profile_area_idx" ON "Profile"("area");

-- CreateIndex
CREATE INDEX "AreaPost_area_idx" ON "AreaPost"("area");

-- CreateIndex
CREATE UNIQUE INDEX "AreaPostInterest_areaPostId_profileId_key" ON "AreaPostInterest"("areaPostId", "profileId");

-- AddForeignKey
ALTER TABLE "AreaPost" ADD CONSTRAINT "AreaPost_profileId_fkey" FOREIGN KEY ("profileId") REFERENCES "Profile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AreaPostInterest" ADD CONSTRAINT "AreaPostInterest_areaPostId_fkey" FOREIGN KEY ("areaPostId") REFERENCES "AreaPost"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AreaPostInterest" ADD CONSTRAINT "AreaPostInterest_profileId_fkey" FOREIGN KEY ("profileId") REFERENCES "Profile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
