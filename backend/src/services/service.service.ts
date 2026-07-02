import prisma from './db'; // Points to your Prisma client instantiation in db.ts

export class ServiceService {
  async fetchMerchantServices(merchantId: string) {
    return prisma.servicePricingMatrix.findMany({
      where: { merchantId },
      include: {
        serviceItem: true,
        species: true,
      },
      orderBy: {
        serviceItem: {
          name: 'asc',
        },
      },
    });
  }

  async createServiceItem(data: { slug: string; name: string }) {
    return prisma.serviceItem.create({ data });
  }

  async createPricingMatrix(data: {
    merchantId: string;
    serviceItemId: number;
    speciesId?: number;
    weightTier?: any;
    coatType?: any;
    nameOverride?: string;
    durationMinutes: number;
    priceCentsAud: number;
  }) {
    return prisma.servicePricingMatrix.create({ data });
  }

  async updatePricingMatrix(id: number, data: Partial<any>) {
    return prisma.servicePricingMatrix.update({
      where: { id },
      data,
    });
  }

  async deletePricingMatrix(id: number) {
    return prisma.servicePricingMatrix.delete({
      where: { id },
    });
  }
}