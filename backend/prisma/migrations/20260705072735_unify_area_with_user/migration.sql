-- Merge the anonymous "My Area" Profile model into the authenticated User.
-- Intentionally destructive for AreaPost/AreaPostInterest/Profile: existing
-- rows were all anonymous demo/seed data, being replaced by an updated seed
-- script that creates real demo Users instead.

-- Add location profile fields to User
ALTER TABLE "User"
  ADD COLUMN "addressLine" TEXT,
  ADD COLUMN "city" TEXT,
  ADD COLUMN "state" TEXT,
  ADD COLUMN "pincode" TEXT,
  ADD COLUMN "area" TEXT,
  ADD COLUMN "latitude" DOUBLE PRECISION,
  ADD COLUMN "longitude" DOUBLE PRECISION;

CREATE INDEX "User_area_idx" ON "User"("area");

-- Drop the old anonymous-profile-based tables
DROP TABLE "AreaPostInterest";
DROP TABLE "AreaPost";
DROP TABLE "Profile";

-- Recreate AreaPost owned by User instead of Profile
CREATE TABLE "AreaPost" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "area" TEXT NOT NULL,
  "latitude" DOUBLE PRECISION,
  "longitude" DOUBLE PRECISION,
  "kind" "AreaPostKind" NOT NULL,
  "title" TEXT NOT NULL,
  "description" TEXT NOT NULL,
  "imageUrls" TEXT[],
  "location" TEXT,
  "sportName" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "AreaPost_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "AreaPost_area_idx" ON "AreaPost"("area");
CREATE INDEX "AreaPost_latitude_longitude_idx" ON "AreaPost"("latitude", "longitude");

ALTER TABLE "AreaPost"
  ADD CONSTRAINT "AreaPost_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Recreate AreaPostInterest owned by User instead of Profile
CREATE TABLE "AreaPostInterest" (
  "id" TEXT NOT NULL,
  "areaPostId" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "AreaPostInterest_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "AreaPostInterest_areaPostId_userId_key" ON "AreaPostInterest"("areaPostId", "userId");

ALTER TABLE "AreaPostInterest"
  ADD CONSTRAINT "AreaPostInterest_areaPostId_fkey" FOREIGN KEY ("areaPostId") REFERENCES "AreaPost"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "AreaPostInterest"
  ADD CONSTRAINT "AreaPostInterest_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
