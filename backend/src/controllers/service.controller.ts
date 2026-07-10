import { Request, Response } from 'express';
import { WeightTier, CoatType } from '@prisma/client';
import { ServiceService } from '../services/service.service';

const serviceService = new ServiceService();

export class ServiceController {
  async getMerchantServices(req: Request, res: Response): Promise<void> {
    try {
      const merchantId = String(req.params.merchantId);
      const data = await serviceService.fetchMerchantServices(merchantId);
      res.status(200).json({ success: true, data });
    } catch (error: any) {
      res.status(500).json({ success: false, message: error.message });
    }
  }

  async createPricingMatrix(req: Request, res: Response): Promise<void> {
    try {
      const { 
        merchantId, 
        name, 
        speciesId, 
        weightTier, 
        coatType, 
        durationMinutes, 
        priceCentsAud 
      } = req.body;

      const matrix = await serviceService.createPricingMatrix({
        merchantId: String(merchantId),
        name: String(name),
        speciesId: speciesId ? Number(speciesId) : undefined,
        weightTier: weightTier ? (String(weightTier) as WeightTier) : undefined,
        coatType: coatType ? (String(coatType) as CoatType) : undefined,
        durationMinutes: Number(durationMinutes),
        priceCentsAud: Number(priceCentsAud)
      });

      res.status(201).json({ success: true, data: matrix });
    } catch (error: any) {
      res.status(400).json({ success: false, message: error.message });
    }
  }

  async updatePricingMatrix(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const updated = await serviceService.updatePricingMatrix(Number(id), req.body);
      res.status(200).json({ success: true, data: updated });
    } catch (error: any) {
      res.status(400).json({ success: false, message: error.message });
    }
  }

  async deletePricingMatrix(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      // Highlights: Now fires the soft deactivation service layer routine instead of erasing data
      await serviceService.deletePricingMatrix(Number(id));
      res.status(200).json({ success: true, message: 'Service set to inactive status successfully.' });
    } catch (error: any) {
      res.status(400).json({ success: false, message: error.message });
    }
  }
}