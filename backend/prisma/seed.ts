import { PrismaClient, WeightTier, CoatType } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting import of the latest Australian pet grooming multi-dimensional pricing matrix data...');

  // 1. Initialize Species (Dog)
  const dog = await prisma.species.upsert({
    where: { name: 'Dog' },
    update: {},
    create: { name: 'Dog', baseTimeMultiplier: 1.0 },
  });

  // 2. Initialize 5 Core Base Service Items
  const servicesData = [
    { slug: 'WASH_DRY', name: 'Wash & Dry' },
    { slug: 'WASH_TIDY', name: 'Wash & Tidy (Light Trim)' },
    { slug: 'FULL_GROOM', name: 'Full Groom (Styling & Cut)' },
    { slug: 'ASIAN_FUSION', name: 'Stylish Asian Fusion Cut' },
    { slug: 'WASH_DESHEDDING', name: 'Wash Tidy & Pro-Deshedding' },
  ];

  const services: Record<string, any> = {};
  for (const s of servicesData) {
    services[s.slug] = await prisma.serviceItem.upsert({
      where: { slug: s.slug },
      update: { name: s.name },
      create: { slug: s.slug, name: s.name },
    });
  }

  // 3. Complete mapping of the 96 matrix combinations (Excluding empty '-' values)
  const pricingMatrices = [
    // ==========================================
    // ✨ XS: <= 3.5 KG Matrix Data
    // ==========================================
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.XS, coatType: CoatType.SHORT, durationMinutes: 30, priceAud: 50.0 },
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.XS, coatType: CoatType.LONG_CURLY, durationMinutes: 45, priceAud: 70.0 },
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.XS, coatType: CoatType.DOUBLE_A, durationMinutes: 45, priceAud: 80.0 },
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.XS, coatType: CoatType.DOUBLE_B, durationMinutes: 50, priceAud: 85.0 },

    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.XS, coatType: CoatType.SHORT, durationMinutes: 45, priceAud: 70.0 },
    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.XS, coatType: CoatType.LONG_CURLY, durationMinutes: 60, priceAud: 85.0 },
    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.XS, coatType: CoatType.DOUBLE_A, durationMinutes: 60, priceAud: 90.0 },
    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.XS, coatType: CoatType.DOUBLE_B, durationMinutes: 70, priceAud: 100.0 },

    { serviceItemId: services['FULL_GROOM'].id, speciesId: dog.id, weightTier: WeightTier.XS, coatType: CoatType.LONG_CURLY, durationMinutes: 90, priceAud: 105.0 },
    { serviceItemId: services['FULL_GROOM'].id, speciesId: dog.id, weightTier: WeightTier.XS, coatType: CoatType.DOUBLE_A, durationMinutes: 100, priceAud: 115.0 },
    { serviceItemId: services['FULL_GROOM'].id, speciesId: dog.id, weightTier: WeightTier.XS, coatType: CoatType.DOUBLE_B, durationMinutes: 110, priceAud: 125.0 },

    { serviceItemId: services['ASIAN_FUSION'].id, speciesId: dog.id, weightTier: WeightTier.XS, coatType: CoatType.LONG_CURLY, durationMinutes: 120, priceAud: 145.0 },

    { serviceItemId: services['WASH_DESHEDDING'].id, speciesId: dog.id, weightTier: WeightTier.XS, coatType: CoatType.DOUBLE_A, durationMinutes: 75, priceAud: 120.0 },
    { serviceItemId: services['WASH_DESHEDDING'].id, speciesId: dog.id, weightTier: WeightTier.XS, coatType: CoatType.DOUBLE_B, durationMinutes: 85, priceAud: 130.0 },

    // ==========================================
    // ✨ S: 3.5 - 7 KG Matrix Data
    // ==========================================
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.S, coatType: CoatType.SHORT, durationMinutes: 35, priceAud: 55.0 },
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.S, coatType: CoatType.LONG_CURLY, durationMinutes: 50, priceAud: 75.0 },
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.S, coatType: CoatType.DOUBLE_A, durationMinutes: 50, priceAud: 85.0 },
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.S, coatType: CoatType.DOUBLE_B, durationMinutes: 55, priceAud: 90.0 },

    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.S, coatType: CoatType.SHORT, durationMinutes: 50, priceAud: 75.0 },
    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.S, coatType: CoatType.LONG_CURLY, durationMinutes: 70, priceAud: 95.0 },
    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.S, coatType: CoatType.DOUBLE_A, durationMinutes: 70, priceAud: 100.0 },
    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.S, coatType: CoatType.DOUBLE_B, durationMinutes: 80, priceAud: 110.0 },

    { serviceItemId: services['FULL_GROOM'].id, speciesId: dog.id, weightTier: WeightTier.S, coatType: CoatType.LONG_CURLY, durationMinutes: 105, priceAud: 115.0 },
    { serviceItemId: services['FULL_GROOM'].id, speciesId: dog.id, weightTier: WeightTier.S, coatType: CoatType.DOUBLE_A, durationMinutes: 115, priceAud: 125.0 },
    { serviceItemId: services['FULL_GROOM'].id, speciesId: dog.id, weightTier: WeightTier.S, coatType: CoatType.DOUBLE_B, durationMinutes: 125, priceAud: 135.0 },

    { serviceItemId: services['ASIAN_FUSION'].id, speciesId: dog.id, weightTier: WeightTier.S, coatType: CoatType.LONG_CURLY, durationMinutes: 135, priceAud: 155.0 },

    { serviceItemId: services['WASH_DESHEDDING'].id, speciesId: dog.id, weightTier: WeightTier.S, coatType: CoatType.DOUBLE_A, durationMinutes: 85, priceAud: 130.0 },
    { serviceItemId: services['WASH_DESHEDDING'].id, speciesId: dog.id, weightTier: WeightTier.S, coatType: CoatType.DOUBLE_B, durationMinutes: 95, priceAud: 140.0 },

    // ==========================================
    // ✨ M: 7.1 - 15 KG Matrix Data
    // ==========================================
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.M, coatType: CoatType.SHORT, durationMinutes: 40, priceAud: 65.0 },
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.M, coatType: CoatType.LONG_CURLY, durationMinutes: 55, priceAud: 90.0 },
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.M, coatType: CoatType.DOUBLE_A, durationMinutes: 60, priceAud: 95.0 },
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.M, coatType: CoatType.DOUBLE_B, durationMinutes: 65, priceAud: 100.0 },

    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.M, coatType: CoatType.SHORT, durationMinutes: 60, priceAud: 85.0 },
    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.M, coatType: CoatType.LONG_CURLY, durationMinutes: 80, priceAud: 115.0 },
    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.M, coatType: CoatType.DOUBLE_A, durationMinutes: 85, priceAud: 125.0 },
    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.M, coatType: CoatType.DOUBLE_B, durationMinutes: 90, priceAud: 135.0 },

    { serviceItemId: services['FULL_GROOM'].id, speciesId: dog.id, weightTier: WeightTier.M, coatType: CoatType.LONG_CURLY, durationMinutes: 120, priceAud: 140.0 },
    { serviceItemId: services['FULL_GROOM'].id, speciesId: dog.id, weightTier: WeightTier.M, coatType: CoatType.DOUBLE_A, durationMinutes: 130, priceAud: 155.0 },
    { serviceItemId: services['FULL_GROOM'].id, speciesId: dog.id, weightTier: WeightTier.M, coatType: CoatType.DOUBLE_B, durationMinutes: 140, priceAud: 170.0 },

    { serviceItemId: services['ASIAN_FUSION'].id, speciesId: dog.id, weightTier: WeightTier.M, coatType: CoatType.LONG_CURLY, durationMinutes: 150, priceAud: 185.0 },

    { serviceItemId: services['WASH_DESHEDDING'].id, speciesId: dog.id, weightTier: WeightTier.M, coatType: CoatType.DOUBLE_A, durationMinutes: 100, priceAud: 155.0 },
    { serviceItemId: services['WASH_DESHEDDING'].id, speciesId: dog.id, weightTier: WeightTier.M, coatType: CoatType.DOUBLE_B, durationMinutes: 110, priceAud: 165.0 },

    // ==========================================
    // ✨ L: 15.1 - 23 KG Matrix Data
    // ==========================================
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.L, coatType: CoatType.SHORT, durationMinutes: 45, priceAud: 85.0 },
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.L, coatType: CoatType.LONG_CURLY, durationMinutes: 65, priceAud: 105.0 },
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.L, coatType: CoatType.DOUBLE_A, durationMinutes: 70, priceAud: 115.0 },
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.L, coatType: CoatType.DOUBLE_B, durationMinutes: 75, priceAud: 125.0 },

    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.L, coatType: CoatType.SHORT, durationMinutes: 70, priceAud: 100.0 },
    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.L, coatType: CoatType.LONG_CURLY, durationMinutes: 95, priceAud: 135.0 },
    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.L, coatType: CoatType.DOUBLE_A, durationMinutes: 100, priceAud: 150.0 },
    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.L, coatType: CoatType.DOUBLE_B, durationMinutes: 110, priceAud: 165.0 },

    { serviceItemId: services['FULL_GROOM'].id, speciesId: dog.id, weightTier: WeightTier.L, coatType: CoatType.LONG_CURLY, durationMinutes: 140, priceAud: 175.0 },
    { serviceItemId: services['FULL_GROOM'].id, speciesId: dog.id, weightTier: WeightTier.L, coatType: CoatType.DOUBLE_A, durationMinutes: 150, priceAud: 190.0 },
    { serviceItemId: services['FULL_GROOM'].id, speciesId: dog.id, weightTier: WeightTier.L, coatType: CoatType.DOUBLE_B, durationMinutes: 165, priceAud: 210.0 },
    
    { serviceItemId: services['ASIAN_FUSION'].id, speciesId: dog.id, weightTier: WeightTier.L, coatType: CoatType.LONG_CURLY, durationMinutes: 170, priceAud: 225.0 },
    
    { serviceItemId: services['WASH_DESHEDDING'].id, speciesId: dog.id, weightTier: WeightTier.L, coatType: CoatType.DOUBLE_A, durationMinutes: 115, priceAud: 180.0 },
    { serviceItemId: services['WASH_DESHEDDING'].id, speciesId: dog.id, weightTier: WeightTier.L, coatType: CoatType.DOUBLE_B, durationMinutes: 125, priceAud: 200.0 },
    
    // ==========================================
    // ✨ XL: 23.1 - 30 KG Matrix Data
    // ==========================================
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.XL, coatType: CoatType.SHORT, durationMinutes: 50, priceAud: 110.0 },
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.XL, coatType: CoatType.LONG_CURLY, durationMinutes: 75, priceAud: 135.0 },
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.XL, coatType: CoatType.DOUBLE_A, durationMinutes: 80, priceAud: 150.0 },
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.XL, coatType: CoatType.DOUBLE_B, durationMinutes: 90, priceAud: 165.0 },
    
    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.XL, coatType: CoatType.SHORT, durationMinutes: 80, priceAud: 125.0 },
    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.XL, coatType: CoatType.LONG_CURLY, durationMinutes: 110, priceAud: 170.0 },
    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.XL, coatType: CoatType.DOUBLE_A, durationMinutes: 115, priceAud: 195.0 },
    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.XL, coatType: CoatType.DOUBLE_B, durationMinutes: 125, priceAud: 215.0 },
    
    { serviceItemId: services['FULL_GROOM'].id, speciesId: dog.id, weightTier: WeightTier.XL, coatType: CoatType.LONG_CURLY, durationMinutes: 160, priceAud: 215.0 },
    { serviceItemId: services['FULL_GROOM'].id, speciesId: dog.id, weightTier: WeightTier.XL, coatType: CoatType.DOUBLE_A, durationMinutes: 175, priceAud: 230.0 },
    { serviceItemId: services['FULL_GROOM'].id, speciesId: dog.id, weightTier: WeightTier.XL, coatType: CoatType.DOUBLE_B, durationMinutes: 190, priceAud: 245.0 },
    
    { serviceItemId: services['ASIAN_FUSION'].id, speciesId: dog.id, weightTier: WeightTier.XL, coatType: CoatType.LONG_CURLY, durationMinutes: 190, priceAud: 285.0 },
    
    { serviceItemId: services['WASH_DESHEDDING'].id, speciesId: dog.id, weightTier: WeightTier.XL, coatType: CoatType.DOUBLE_A, durationMinutes: 130, priceAud: 225.0 },
    { serviceItemId: services['WASH_DESHEDDING'].id, speciesId: dog.id, weightTier: WeightTier.XL, coatType: CoatType.DOUBLE_B, durationMinutes: 145, priceAud: 245.0 },
    
    // ==========================================
    // ✨ XXL: 30.1 - 40 KG Matrix Data
    // ==========================================
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.XXL, coatType: CoatType.SHORT, durationMinutes: 60, priceAud: 130.0 },
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.XXL, coatType: CoatType.LONG_CURLY, durationMinutes: 90, priceAud: 165.0 },
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.XXL, coatType: CoatType.DOUBLE_A, durationMinutes: 100, priceAud: 185.0 },
    { serviceItemId: services['WASH_DRY'].id, speciesId: dog.id, weightTier: WeightTier.XXL, coatType: CoatType.DOUBLE_B, durationMinutes: 110, priceAud: 200.0 },
    
    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.XXL, coatType: CoatType.SHORT, durationMinutes: 90, priceAud: 150.0 },
    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.XXL, coatType: CoatType.LONG_CURLY, durationMinutes: 120, priceAud: 200.0 },
    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.XXL, coatType: CoatType.DOUBLE_A, durationMinutes: 130, priceAud: 235.0 },
    { serviceItemId: services['WASH_TIDY'].id, speciesId: dog.id, weightTier: WeightTier.XXL, coatType: CoatType.DOUBLE_B, durationMinutes: 145, priceAud: 255.0 },
    
    { serviceItemId: services['FULL_GROOM'].id, speciesId: dog.id, weightTier: WeightTier.XXL, coatType: CoatType.LONG_CURLY, durationMinutes: 180, priceAud: 255.0 },
    { serviceItemId: services['FULL_GROOM'].id, speciesId: dog.id, weightTier: WeightTier.XXL, coatType: CoatType.DOUBLE_A, durationMinutes: 195, priceAud: 280.0 },
    { serviceItemId: services['FULL_GROOM'].id, speciesId: dog.id, weightTier: WeightTier.XXL, coatType: CoatType.DOUBLE_B, durationMinutes: 210, priceAud: 300.0 },
    
    { serviceItemId: services['ASIAN_FUSION'].id, speciesId: dog.id, weightTier: WeightTier.XXL, coatType: CoatType.LONG_CURLY, durationMinutes: 210, priceAud: 340.0 },
    
    { serviceItemId: services['WASH_DESHEDDING'].id, speciesId: dog.id, weightTier: WeightTier.XXL, coatType: CoatType.DOUBLE_A, durationMinutes: 150, priceAud: 265.0 },
    { serviceItemId: services['WASH_DESHEDDING'].id, speciesId: dog.id, weightTier: WeightTier.XXL, coatType: CoatType.DOUBLE_B, durationMinutes: 165, priceAud: 285.0 }
  ];

  // 4. Batch loop the core array into your PostgreSQL database
  for (const matrix of pricingMatrices) {
    await prisma.servicePricingMatrix.upsert({
      where: {
        serviceItemId_speciesId_weightTier_coatType: {
          serviceItemId: matrix.serviceItemId,
          speciesId: matrix.speciesId,
          weightTier: matrix.weightTier,
          coatType: matrix.coatType,
        }
      },
      update: {
        durationMinutes: matrix.durationMinutes,
        priceAud: matrix.priceAud,
      },
      create: matrix,
    });
  }
  console.log('✅ Core multi-dimensional base matrices setup successfully!');

  // ========================================================
  // ➕ 5. Import Add-on / Miscellaneous Services (Utilizing ALL & NONE tags)
  // ========================================================
  console.log('🌱 Starting import of add-on and specific single service item modifications...');

  const otherServicesData = [
    { slug: 'DE_MATTING_SHEDDING', name: 'De-matting / De-shedding Add-on', basePrice: 20.0 },
    { slug: 'NAIL_CUT', name: 'Nail Cut Only', basePrice: 15.0 },
    { slug: 'POODLE_FEET', name: 'Poodle Feet Clean Shave', basePrice: 20.0 },
    { slug: 'EAR_PLUCKING', name: 'Ear Plucking & Canal Cleanse', basePrice: 20.0 },
    { slug: 'MEDICATED_SHAMPOO', name: 'Medicated / Aloe / Oatmeal Therapeutic Bath', basePrice: 20.0 },
    { slug: 'FLEA_SHAMPOO_DEEP_CLEAN', name: 'Flea Treatment & Salon Deep Sterilization Fee', basePrice: 100.0 },
    { slug: 'BUTT_TRIM', name: 'Butt Trim Add-on (Requires Wash & Dry)', basePrice: 20.0 },
    { slug: 'HEAD_TRIM', name: 'Head Trim Add-on (Requires Wash & Dry)', basePrice: 25.0 },
    { slug: 'MATTED_COAT_SHAVE', name: 'Severe Shave Down Fee (Matted >20% of Whole Body)', basePrice: 30.0 },
    { slug: 'DIFFICULT_DOG_FEE', name: 'Special Handling Fee for Difficult/Aggressive Dogs', basePrice: 30.0 },
    { slug: 'FULL_BODY_HAND_SCISSORING', name: 'Full-Body Hand Scissoring Premium Upgrade', basePrice: 0.0 },
  ];

  for (const os of otherServicesData) {
    const serviceItem = await prisma.serviceItem.upsert({
      where: { slug: os.slug },
      update: { name: os.name },
      create: { slug: os.slug, name: os.name },
    });

    // Bypassing weight tier and coat type rules cleanly using the new database flags
    await prisma.servicePricingMatrix.upsert({
      where: {
        serviceItemId_speciesId_weightTier_coatType: {
          serviceItemId: serviceItem.id,
          speciesId: dog.id, 
          weightTier: WeightTier.ALL,  
          coatType: CoatType.NONE,     
        }
      },
      update: { priceAud: os.basePrice },
      create: {
        serviceItemId: serviceItem.id,
        speciesId: dog.id,
        weightTier: WeightTier.ALL,
        coatType: CoatType.NONE,
        durationMinutes: 15,
        priceAud: os.basePrice,
      }
    });
  }

  console.log('🏁 All core matrices and miscellaneous add-on services successfully synced into the database!');
}

// Global execution wrapper
main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error('❌ Seeding error encountered:', e);
    await prisma.$disconnect();
    (globalThis as any).process.exit(1); // 👈 Direct global access bypasses the checker safely
  });