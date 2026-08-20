import { WeightTier, CoatType, AddOnPricingType } from '@prisma/client'; 
import prisma from './db'; 

export class ServiceService {
  async fetchMerchantServices(merchantId: string) {
    return prisma.servicePricingMatrix.findMany({
      where: { 
        merchantId,
        isActive: true 
      },
      include: {
        species: true,
      },
      orderBy: {
        name: 'asc',
      },
    });
  }

  async createPricingMatrix(data: {
    merchantId: string;
    name: string;
    description: string;
    speciesId?: number;
    weightTier?: WeightTier;
    coatType?: CoatType;
    durationMinutes: number;
    priceCentsAud: number;
    depositCentsAud: number;
  }) {
    return prisma.servicePricingMatrix.create({
      data: {
        merchantId: data.merchantId,
        name: data.name,
        description: data.description,
        speciesId: data.speciesId,
        weightTier: data.weightTier,
        coatType: data.coatType,
        durationMinutes: data.durationMinutes,
        priceCentsAud: data.priceCentsAud,
        depositCentsAud: data.depositCentsAud
      }
    });
  }

  async updatePricingMatrix(id: number, data: Partial<any>) {
    return prisma.servicePricingMatrix.update({
      where: { id },
      data,
    });
  }

  async deletePricingMatrix(id: number) {
    return prisma.servicePricingMatrix.update({
      where: { id },
      data: { isActive: false },
    });
  }

  // --- ADD-ON MANAGEMENT METHODS ---
  async getMerchantAddOns(merchantId: string) {
    return prisma.addOn.findMany({
      where: { merchantId, isActive: true },
      orderBy: { name: 'asc' },
    });
  }

  async createAddOn(data: {
    merchantId: string;
    name: string;
    description?: string;
    priceCentsAud: number;
    pricingType?: AddOnPricingType;
    durationMinutes?: number;
  }) {
    return prisma.addOn.create({
      data: {
        merchantId: data.merchantId,
        name: data.name,
        description: data.description,
        priceCentsAud: data.priceCentsAud,
        pricingType: data.pricingType || AddOnPricingType.FIXED,
        durationMinutes: data.durationMinutes || 0,
      },
    });
  }

  async seedDefaultAddOnsIfEmpty(merchantId: string) {
    const existingCount = await prisma.addOn.count({ where: { merchantId } });
    if (existingCount > 0) return;

    // Seed options matching the UI screenshot
    await prisma.addOn.createMany({
      data: [
        { merchantId, name: 'Teeth brush', priceCentsAud: 1500, pricingType: AddOnPricingType.FIXED }, // $15
        { merchantId, name: 'De-shedding', priceCentsAud: 150, pricingType: AddOnPricingType.PER_MINUTE }, // $1.5 per minute
        { merchantId, name: 'Poodle feet', priceCentsAud: 2000, pricingType: AddOnPricingType.FIXED }, // $20
        { merchantId, name: 'De-matting', priceCentsAud: 150, pricingType: AddOnPricingType.PER_MINUTE }, // $1.5 per minute
        { merchantId, name: 'Ear hair plucking', priceCentsAud: 2000, pricingType: AddOnPricingType.FIXED }, // $20
      ],
    });
  }
}