-- AlterTable
ALTER TABLE "Appointment" ADD COLUMN     "depositPaid" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "internalTags" TEXT[],
ADD COLUMN     "isCheckedIn" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "isReadyToPickup" BOOLEAN NOT NULL DEFAULT false;
