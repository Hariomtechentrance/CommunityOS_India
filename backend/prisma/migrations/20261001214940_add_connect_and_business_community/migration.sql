-- AlterEnum
ALTER TYPE "SocietyType" ADD VALUE 'BUSINESS';

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "connectEnabled" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "interests" TEXT[] DEFAULT ARRAY[]::TEXT[];
