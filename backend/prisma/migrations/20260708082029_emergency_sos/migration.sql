-- AlterEnum
ALTER TYPE "AreaPostKind" ADD VALUE 'EMERGENCY_SOS';

-- AlterTable
ALTER TABLE "AreaPost" ADD COLUMN     "emergencyCategory" TEXT;

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "fcmToken" TEXT;
