-- CreateEnum
CREATE TYPE "CampaignObjective" AS ENUM ('SALES', 'DOWNLOADS', 'AWARENESS', 'ENGAGEMENT');

-- CreateEnum
CREATE TYPE "CampaignTargetType" AS ENUM ('NEARBY', 'PINCODE', 'STATES', 'ALL_INDIA');

-- CreateEnum
CREATE TYPE "CampaignStatus" AS ENUM ('DRAFT', 'PENDING_PAYMENT', 'ACTIVE', 'COMPLETED', 'REJECTED');

-- CreateTable
CREATE TABLE "Campaign" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "objective" "CampaignObjective" NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "imageUrl" TEXT,
    "ctaUrl" TEXT,
    "targetType" "CampaignTargetType" NOT NULL,
    "targetPincode" TEXT,
    "targetStates" TEXT[],
    "targetLatitude" DOUBLE PRECISION,
    "targetLongitude" DOUBLE PRECISION,
    "targetRadiusKm" DOUBLE PRECISION,
    "budgetInPaise" INTEGER NOT NULL,
    "status" "CampaignStatus" NOT NULL DEFAULT 'DRAFT',
    "startDate" TIMESTAMP(3),
    "endDate" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Campaign_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CampaignPayment" (
    "id" TEXT NOT NULL,
    "campaignId" TEXT NOT NULL,
    "razorpayLinkId" TEXT NOT NULL,
    "razorpayPaymentId" TEXT,
    "amountInPaise" INTEGER NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'created',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CampaignPayment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CampaignImpression" (
    "id" TEXT NOT NULL,
    "campaignId" TEXT NOT NULL,
    "userId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CampaignImpression_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Campaign_status_idx" ON "Campaign"("status");

-- CreateIndex
CREATE INDEX "Campaign_targetPincode_idx" ON "Campaign"("targetPincode");

-- CreateIndex
CREATE UNIQUE INDEX "CampaignPayment_razorpayLinkId_key" ON "CampaignPayment"("razorpayLinkId");

-- CreateIndex
CREATE INDEX "CampaignImpression_campaignId_idx" ON "CampaignImpression"("campaignId");

-- AddForeignKey
ALTER TABLE "Campaign" ADD CONSTRAINT "Campaign_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CampaignPayment" ADD CONSTRAINT "CampaignPayment_campaignId_fkey" FOREIGN KEY ("campaignId") REFERENCES "Campaign"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CampaignImpression" ADD CONSTRAINT "CampaignImpression_campaignId_fkey" FOREIGN KEY ("campaignId") REFERENCES "Campaign"("id") ON DELETE CASCADE ON UPDATE CASCADE;
