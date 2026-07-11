-- CreateEnum
CREATE TYPE "AreaPostVisibility" AS ENUM ('PINCODE_ONLY', 'NEARBY');

-- AlterEnum
ALTER TYPE "AreaPostKind" ADD VALUE 'SERVICE_REQUEST';

-- AlterTable
ALTER TABLE "AreaPost" ADD COLUMN     "businessCategory" TEXT,
ADD COLUMN     "offerText" TEXT,
ADD COLUMN     "pincode" TEXT,
ADD COLUMN     "serviceType" TEXT,
ADD COLUMN     "visibility" "AreaPostVisibility" NOT NULL DEFAULT 'NEARBY';

-- CreateTable
CREATE TABLE "Message" (
    "id" TEXT NOT NULL,
    "senderId" TEXT NOT NULL,
    "receiverId" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Message_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Message_senderId_receiverId_idx" ON "Message"("senderId", "receiverId");

-- CreateIndex
CREATE INDEX "Message_receiverId_senderId_idx" ON "Message"("receiverId", "senderId");

-- AddForeignKey
ALTER TABLE "Message" ADD CONSTRAINT "Message_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Message" ADD CONSTRAINT "Message_receiverId_fkey" FOREIGN KEY ("receiverId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
