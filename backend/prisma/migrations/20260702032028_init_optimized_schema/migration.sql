-- CreateEnum
CREATE TYPE "PetStatus" AS ENUM ('ACTIVE', 'LOST', 'ANGEL');

-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('MERCHANT_ADMIN', 'MERCHANT_STAFF', 'CUSTOMER');

-- CreateEnum
CREATE TYPE "Gender" AS ENUM ('MALE', 'FEMALE', 'UNKNOWN');

-- CreateEnum
CREATE TYPE "AppointmentStatus" AS ENUM ('PENDING', 'PAID', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "WeightTier" AS ENUM ('XS', 'S', 'M', 'L', 'XL', 'XXL', 'ALL');

-- CreateEnum
CREATE TYPE "CoatType" AS ENUM ('SHORT', 'LONG_CURLY', 'DOUBLE_A', 'DOUBLE_B', 'NONE');

-- CreateEnum
CREATE TYPE "LogCategory" AS ENUM ('AUTH', 'ACTIVITY', 'SECURITY');

-- CreateEnum
CREATE TYPE "HttpMethod" AS ENUM ('GET', 'POST', 'PUT', 'DELETE', 'PATCH');

-- CreateTable
CREATE TABLE "Species" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "baseTimeMultiplier" DOUBLE PRECISION NOT NULL DEFAULT 1.0,

    CONSTRAINT "Species_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Pet" (
    "id" TEXT NOT NULL,
    "ownerId" TEXT NOT NULL,
    "speciesId" INTEGER NOT NULL,
    "merchantId" TEXT NOT NULL,
    "breed" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "microchipNumber" TEXT,
    "status" "PetStatus" NOT NULL DEFAULT 'ACTIVE',
    "gender" "Gender" NOT NULL DEFAULT 'UNKNOWN',
    "isDesexed" BOOLEAN NOT NULL DEFAULT false,
    "dob" TIMESTAMP(3),
    "behaviorTags" TEXT[],
    "behaviorNotes" TEXT,
    "loyaltyGroomCount" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "Pet_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Appointment" (
    "id" TEXT NOT NULL,
    "petId" TEXT NOT NULL,
    "groomerId" TEXT NOT NULL,
    "merchantId" TEXT NOT NULL,
    "startTime" TIMESTAMP(3) NOT NULL,
    "endTime" TIMESTAMP(3) NOT NULL,
    "status" "AppointmentStatus" NOT NULL DEFAULT 'PENDING',
    "serviceItemId" INTEGER NOT NULL,
    "priceCentsAud" INTEGER NOT NULL,
    "durationMinutes" INTEGER NOT NULL,
    "isLoyaltyWaived" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "Appointment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ServiceItem" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "ServiceItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ServicePricingMatrix" (
    "id" SERIAL NOT NULL,
    "merchantId" TEXT NOT NULL,
    "serviceItemId" INTEGER NOT NULL,
    "speciesId" INTEGER,
    "weightTier" "WeightTier",
    "coatType" "CoatType",
    "nameOverride" TEXT,
    "durationMinutes" INTEGER NOT NULL,
    "priceCentsAud" INTEGER NOT NULL,

    CONSTRAINT "ServicePricingMatrix_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "merchantId" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "phoneNumber" TEXT,
    "passwordHash" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "avatarUrl" TEXT,
    "role" "UserRole" NOT NULL DEFAULT 'CUSTOMER',
    "countryCode" TEXT NOT NULL DEFAULT 'AU',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Merchant" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "businessName" TEXT NOT NULL,
    "abn" TEXT,
    "stripeAccountId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "logoIcon" TEXT,
    "logoUrl" TEXT,
    "primaryColor" TEXT NOT NULL DEFAULT '#FF05050E',
    "tags" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "businessTags" JSONB,
    "uiDictionary" JSONB,

    CONSTRAINT "Merchant_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Employee" (
    "id" TEXT NOT NULL,
    "merchantId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "avatarUrl" TEXT,

    CONSTRAINT "Employee_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ActivityLog" (
    "id" TEXT NOT NULL,
    "merchantId" TEXT NOT NULL,
    "userId" TEXT,
    "category" "LogCategory" NOT NULL DEFAULT 'ACTIVITY',
    "moduleName" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "description" TEXT,
    "ipAddress" TEXT,
    "userAgent" TEXT,
    "path" TEXT,
    "method" "HttpMethod",
    "metaData" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ActivityLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AppointmentAddOn" (
    "appointmentId" TEXT NOT NULL,
    "matrixId" INTEGER NOT NULL,

    CONSTRAINT "AppointmentAddOn_pkey" PRIMARY KEY ("appointmentId","matrixId")
);

-- CreateTable
CREATE TABLE "WaiverSignature" (
    "id" TEXT NOT NULL,
    "merchantId" TEXT NOT NULL,
    "ownerId" TEXT NOT NULL,
    "ipAddress" TEXT NOT NULL,
    "signedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "termsVersion" TEXT NOT NULL,

    CONSTRAINT "WaiverSignature_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BusinessHours" (
    "id" SERIAL NOT NULL,
    "merchantId" TEXT NOT NULL,
    "dayOfWeek" INTEGER NOT NULL,
    "openTime" TEXT NOT NULL,
    "closeTime" TEXT NOT NULL,
    "isClosed" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "BusinessHours_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RosterException" (
    "id" TEXT NOT NULL,
    "employeeId" TEXT NOT NULL,
    "merchantId" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "startTime" TEXT,
    "endTime" TEXT,
    "reason" TEXT,

    CONSTRAINT "RosterException_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Species_name_key" ON "Species"("name");

-- CreateIndex
CREATE UNIQUE INDEX "Pet_microchipNumber_key" ON "Pet"("microchipNumber");

-- CreateIndex
CREATE INDEX "Pet_merchantId_name_status_idx" ON "Pet"("merchantId", "name", "status");

-- CreateIndex
CREATE INDEX "Pet_merchantId_ownerId_idx" ON "Pet"("merchantId", "ownerId");

-- CreateIndex
CREATE INDEX "Appointment_merchantId_startTime_groomerId_idx" ON "Appointment"("merchantId", "startTime", "groomerId");

-- CreateIndex
CREATE UNIQUE INDEX "ServiceItem_slug_key" ON "ServiceItem"("slug");

-- CreateIndex
CREATE INDEX "ServicePricingMatrix_serviceItemId_speciesId_idx" ON "ServicePricingMatrix"("serviceItemId", "speciesId");

-- CreateIndex
CREATE UNIQUE INDEX "ServicePricingMatrix_merchantId_serviceItemId_speciesId_wei_key" ON "ServicePricingMatrix"("merchantId", "serviceItemId", "speciesId", "weightTier", "coatType");

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "User_phoneNumber_key" ON "User"("phoneNumber");

-- CreateIndex
CREATE INDEX "User_merchantId_createdAt_idx" ON "User"("merchantId", "createdAt");

-- CreateIndex
CREATE INDEX "User_merchantId_name_idx" ON "User"("merchantId", "name");

-- CreateIndex
CREATE UNIQUE INDEX "Merchant_email_key" ON "Merchant"("email");

-- CreateIndex
CREATE UNIQUE INDEX "Merchant_stripeAccountId_key" ON "Merchant"("stripeAccountId");

-- CreateIndex
CREATE INDEX "Employee_merchantId_idx" ON "Employee"("merchantId");

-- CreateIndex
CREATE INDEX "ActivityLog_merchantId_createdAt_idx" ON "ActivityLog"("merchantId", "createdAt");

-- CreateIndex
CREATE INDEX "ActivityLog_merchantId_category_idx" ON "ActivityLog"("merchantId", "category");

-- CreateIndex
CREATE INDEX "ActivityLog_merchantId_userId_idx" ON "ActivityLog"("merchantId", "userId");

-- CreateIndex
CREATE UNIQUE INDEX "WaiverSignature_merchantId_ownerId_key" ON "WaiverSignature"("merchantId", "ownerId");

-- CreateIndex
CREATE UNIQUE INDEX "BusinessHours_merchantId_dayOfWeek_key" ON "BusinessHours"("merchantId", "dayOfWeek");

-- AddForeignKey
ALTER TABLE "Pet" ADD CONSTRAINT "Pet_speciesId_fkey" FOREIGN KEY ("speciesId") REFERENCES "Species"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Pet" ADD CONSTRAINT "Pet_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Pet" ADD CONSTRAINT "Pet_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Appointment" ADD CONSTRAINT "Appointment_petId_fkey" FOREIGN KEY ("petId") REFERENCES "Pet"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Appointment" ADD CONSTRAINT "Appointment_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Appointment" ADD CONSTRAINT "Appointment_groomerId_fkey" FOREIGN KEY ("groomerId") REFERENCES "Employee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Appointment" ADD CONSTRAINT "Appointment_serviceItemId_fkey" FOREIGN KEY ("serviceItemId") REFERENCES "ServiceItem"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServicePricingMatrix" ADD CONSTRAINT "ServicePricingMatrix_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServicePricingMatrix" ADD CONSTRAINT "ServicePricingMatrix_serviceItemId_fkey" FOREIGN KEY ("serviceItemId") REFERENCES "ServiceItem"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServicePricingMatrix" ADD CONSTRAINT "ServicePricingMatrix_speciesId_fkey" FOREIGN KEY ("speciesId") REFERENCES "Species"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Employee" ADD CONSTRAINT "Employee_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ActivityLog" ADD CONSTRAINT "ActivityLog_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ActivityLog" ADD CONSTRAINT "ActivityLog_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AppointmentAddOn" ADD CONSTRAINT "AppointmentAddOn_appointmentId_fkey" FOREIGN KEY ("appointmentId") REFERENCES "Appointment"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AppointmentAddOn" ADD CONSTRAINT "AppointmentAddOn_matrixId_fkey" FOREIGN KEY ("matrixId") REFERENCES "ServicePricingMatrix"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WaiverSignature" ADD CONSTRAINT "WaiverSignature_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WaiverSignature" ADD CONSTRAINT "WaiverSignature_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "BusinessHours" ADD CONSTRAINT "BusinessHours_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RosterException" ADD CONSTRAINT "RosterException_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES "Employee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RosterException" ADD CONSTRAINT "RosterException_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
