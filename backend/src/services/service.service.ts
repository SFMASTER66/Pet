import { WeightTier, CoatType } from '@prisma/client'; 
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
    speciesId?: number;
    weightTier?: WeightTier;
    coatType?: CoatType;
    durationMinutes: number;
    priceCentsAud: number;
  }) {
    return prisma.servicePricingMatrix.create({
      data: {
        merchantId: data.merchantId,
        name: data.name,
        speciesId: data.speciesId,
        weightTier: data.weightTier,
        coatType: data.coatType,
        durationMinutes: data.durationMinutes,
        priceCentsAud: data.priceCentsAud,
      }
    });
  }

  async updatePricingMatrix(id: number, data: Partial<any>) {
    return prisma.servicePricingMatrix.update({
      where: { id },
      data,
    });
  }

  // Highlights: Soft Delete Fix - Changed from .delete to an update toggle
  async deletePricingMatrix(id: number) {
    return prisma.servicePricingMatrix.update({
      where: { id },
      data: { isActive: false },
    });
  }
}