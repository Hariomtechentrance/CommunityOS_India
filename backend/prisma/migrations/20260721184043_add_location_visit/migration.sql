-- CreateTable
CREATE TABLE "LocationVisit" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "pincode" TEXT NOT NULL,
    "area" TEXT,
    "city" TEXT,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "lastSeenAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "LocationVisit_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "LocationVisit_userId_lastSeenAt_idx" ON "LocationVisit"("userId", "lastSeenAt");

-- CreateIndex
CREATE UNIQUE INDEX "LocationVisit_userId_pincode_key" ON "LocationVisit"("userId", "pincode");

-- AddForeignKey
ALTER TABLE "LocationVisit" ADD CONSTRAINT "LocationVisit_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
