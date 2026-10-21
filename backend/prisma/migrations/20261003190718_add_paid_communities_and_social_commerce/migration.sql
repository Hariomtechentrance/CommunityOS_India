-- AlterTable
ALTER TABLE "GoalCommunity" ADD COLUMN     "joinCostCoins" INTEGER NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE "Reel" ADD COLUMN     "linkedAreaPostId" TEXT;

-- AddForeignKey
ALTER TABLE "Reel" ADD CONSTRAINT "Reel_linkedAreaPostId_fkey" FOREIGN KEY ("linkedAreaPostId") REFERENCES "AreaPost"("id") ON DELETE SET NULL ON UPDATE CASCADE;
