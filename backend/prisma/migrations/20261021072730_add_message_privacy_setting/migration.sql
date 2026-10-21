-- CreateEnum
CREATE TYPE "MessagePrivacy" AS ENUM ('EVERYONE', 'NO_ONE');

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "allowMessagesFrom" "MessagePrivacy" NOT NULL DEFAULT 'EVERYONE';
