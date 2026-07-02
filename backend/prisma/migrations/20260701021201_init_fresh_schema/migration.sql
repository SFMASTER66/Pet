/*
  Warnings:

  - The values [LONG,DOUBLE] on the enum `CoatType` will be removed. If these variants are still used in the database, this will fail.
  - The values [SMALL,MEDIUM,LARGE,GIANT] on the enum `WeightTier` will be removed. If these variants are still used in the database, this will fail.
  - You are about to drop the column `tenantId` on the `Appointment` table. All the data in the column will be lost.
  - You are about to drop the column `tenantId` on the `Pet` table. All the data in the column will be lost.
  - You are about to drop the column `tenantId` on the `User` table. All the data in the column will be lost.
  - Added the required column `durationMinutes` to the `Appointment` table without a default value. This is not possible if the table is not empty.
  - Added the required column `priceAud` to the `Appointment` table without a default value. This is not possible if the table is not empty.
  - Added the required column `serviceItemId` to the `Appointment` table without a default value. This is not possible if the table is not empty.
  - Added the required column `merchantId` to the `Pet` table without a default value. This is not possible if the table is not empty.
  - Added the required column `merchantId` to the `User` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('MERCHANT_ADMIN', 'MERCHANT_STAFF', 'CUSTOMER');

-- CreateEnum
CREATE TYPE "Gender" AS ENUM ('MALE', 'FEMALE', 'UNKNOWN');

-- AlterEnum
BEGIN;
CREATE TYPE "CoatType_new" AS ENUM ('SHORT', 'LONG_CURLY', 'DOUBLE_A', 'DOUBLE_B', 'NONE');
ALTER TABLE "ServicePricingMatrix" ALTER COLUMN "coatType" TYPE "CoatType_new" USING ("coatType"::text::"CoatType_new");
ALTER TYPE "CoatType" RENAME TO "CoatType_old";
ALTER TYPE "CoatType_new" RENAME TO "CoatType";
DROP TYPE "public"."CoatType_old";
COMMIT;

-- AlterEnum
BEGIN;
CREATE TYPE "WeightTier_new" AS ENUM ('XS', 'S', 'M', 'L', 'XL', 'XXL', 'ALL');
ALTER TABLE "ServicePricingMatrix" ALTER COLUMN "weightTier" TYPE "WeightTier_new" USING ("weightTier"::text::"WeightTier_new");
ALTER TYPE "WeightTier" RENAME TO "WeightTier_old";
ALTER TYPE "WeightTier_new" RENAME TO "WeightTier";
DROP TYPE "public"."WeightTier_old";
COMMIT;

-- DropIndex
DROP INDEX "Appointment_tenantId_startTime_idx";

-- AlterTable
ALTER TABLE "Appointment" DROP COLUMN "tenantId",
ADD COLUMN     "durationMinutes" INTEGER NOT NULL,
ADD COLUMN     "priceAud" DOUBLE PRECISION NOT NULL,
ADD COLUMN     "serviceItemId" INTEGER NOT NULL;

-- AlterTable
ALTER TABLE "Merchant" ADD COLUMN     "logoIcon" TEXT,
ADD COLUMN     "primaryColor" INTEGER NOT NULL DEFAULT 4279203182,
ADD COLUMN     "tags" TEXT[] DEFAULT ARRAY[]::TEXT[];

-- AlterTable
ALTER TABLE "Pet" DROP COLUMN "tenantId",
ADD COLUMN     "behaviorNotes" TEXT,
ADD COLUMN     "dob" TIMESTAMP(3),
ADD COLUMN     "gender" "Gender" NOT NULL DEFAULT 'UNKNOWN',
ADD COLUMN     "isDesexed" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "merchantId" TEXT NOT NULL;

-- AlterTable
ALTER TABLE "User" DROP COLUMN "tenantId",
ADD COLUMN     "merchantId" TEXT NOT NULL,
ADD COLUMN     "role" "UserRole" NOT NULL DEFAULT 'CUSTOMER';

-- CreateIndex
CREATE INDEX "Appointment_merchantId_startTime_idx" ON "Appointment"("merchantId", "startTime");

-- CreateIndex
CREATE INDEX "Pet_merchantId_name_status_idx" ON "Pet"("merchantId", "name", "status");

-- CreateIndex
CREATE INDEX "Pet_merchantId_ownerId_idx" ON "Pet"("merchantId", "ownerId");

-- CreateIndex
CREATE INDEX "User_merchantId_createdAt_idx" ON "User"("merchantId", "createdAt");

-- CreateIndex
CREATE INDEX "User_merchantId_name_idx" ON "User"("merchantId", "name");

-- AddForeignKey
ALTER TABLE "Pet" ADD CONSTRAINT "Pet_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Appointment" ADD CONSTRAINT "Appointment_serviceItemId_fkey" FOREIGN KEY ("serviceItemId") REFERENCES "ServiceItem"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
