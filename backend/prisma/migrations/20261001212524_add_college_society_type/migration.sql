-- CreateEnum
CREATE TYPE "SocietyType" AS ENUM ('APARTMENT', 'COLLEGE');

-- AlterTable
ALTER TABLE "Membership" ADD COLUMN     "collegeEmail" TEXT;

-- AlterTable
ALTER TABLE "Society" ADD COLUMN     "emailDomain" TEXT,
ADD COLUMN     "type" "SocietyType" NOT NULL DEFAULT 'APARTMENT';
