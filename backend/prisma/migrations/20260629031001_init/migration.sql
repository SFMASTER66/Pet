-- CreateEnum
CREATE TYPE "PetStatus" AS ENUM ('ACTIVE', 'LOST', 'ANGEL');

-- CreateEnum
CREATE TYPE "AppointmentStatus" AS ENUM ('PENDING', 'PAID', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "WeightTier" AS ENUM ('SMALL', 'MEDIUM', 'LARGE', 'GIANT', 'ALL');

-- CreateEnum
CREATE TYPE "CoatType" AS ENUM ('SHORT', 'LONG', 'DOUBLE', 'NONE');

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
    "breed" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "microchipNumber" TEXT,
    "status" "PetStatus" NOT NULL DEFAULT 'ACTIVE',
    "behaviorTags" TEXT[],
    "tenantId" TEXT,

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
    "tenantId" TEXT NOT NULL,

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
    "serviceItemId" INTEGER NOT NULL,
    "speciesId" INTEGER NOT NULL,
    "weightTier" "WeightTier" NOT NULL,
    "coatType" "CoatType" NOT NULL,
    "durationMinutes" INTEGER NOT NULL,
    "priceAud" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "ServicePricingMatrix_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "phoneNumber" TEXT,
    "passwordHash" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "avatarUrl" TEXT,
    "countryCode" TEXT NOT NULL DEFAULT 'AU',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "tenantId" TEXT,

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
CREATE TABLE "MerchantBranding" (
    "id" TEXT NOT NULL,
    "merchantId" TEXT NOT NULL,
    "logoUrl" TEXT NOT NULL,
    "primaryColor" TEXT NOT NULL,
    "businessTags" JSONB NOT NULL,

    CONSTRAINT "MerchantBranding_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MerchantUiText" (
    "id" TEXT NOT NULL,
    "merchantId" TEXT NOT NULL,
    "uiDictionary" JSONB NOT NULL,

    CONSTRAINT "MerchantUiText_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MerchantService" (
    "id" TEXT NOT NULL,
    "merchantId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "priceAud" DOUBLE PRECISION NOT NULL,
    "durationMinutes" INTEGER NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "MerchantService_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Species_name_key" ON "Species"("name");

-- CreateIndex
CREATE UNIQUE INDEX "Pet_microchipNumber_key" ON "Pet"("microchipNumber");

-- CreateIndex
CREATE INDEX "Appointment_tenantId_startTime_idx" ON "Appointment"("tenantId", "startTime");

-- CreateIndex
CREATE UNIQUE INDEX "ServiceItem_slug_key" ON "ServiceItem"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "ServicePricingMatrix_serviceItemId_speciesId_weightTier_coa_key" ON "ServicePricingMatrix"("serviceItemId", "speciesId", "weightTier", "coatType");

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "User_phoneNumber_key" ON "User"("phoneNumber");

-- CreateIndex
CREATE UNIQUE INDEX "Merchant_email_key" ON "Merchant"("email");

-- CreateIndex
CREATE UNIQUE INDEX "Merchant_stripeAccountId_key" ON "Merchant"("stripeAccountId");

-- CreateIndex
CREATE UNIQUE INDEX "MerchantBranding_merchantId_key" ON "MerchantBranding"("merchantId");

-- CreateIndex
CREATE UNIQUE INDEX "MerchantUiText_merchantId_key" ON "MerchantUiText"("merchantId");

-- AddForeignKey
ALTER TABLE "Pet" ADD CONSTRAINT "Pet_speciesId_fkey" FOREIGN KEY ("speciesId") REFERENCES "Species"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Pet" ADD CONSTRAINT "Pet_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Appointment" ADD CONSTRAINT "Appointment_petId_fkey" FOREIGN KEY ("petId") REFERENCES "Pet"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Appointment" ADD CONSTRAINT "Appointment_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Appointment" ADD CONSTRAINT "Appointment_groomerId_fkey" FOREIGN KEY ("groomerId") REFERENCES "Employee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServicePricingMatrix" ADD CONSTRAINT "ServicePricingMatrix_serviceItemId_fkey" FOREIGN KEY ("serviceItemId") REFERENCES "ServiceItem"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServicePricingMatrix" ADD CONSTRAINT "ServicePricingMatrix_speciesId_fkey" FOREIGN KEY ("speciesId") REFERENCES "Species"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Employee" ADD CONSTRAINT "Employee_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MerchantBranding" ADD CONSTRAINT "MerchantBranding_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MerchantUiText" ADD CONSTRAINT "MerchantUiText_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MerchantService" ADD CONSTRAINT "MerchantService_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
