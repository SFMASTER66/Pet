import { Request, Response } from 'express';
import { ServiceService } from '../services/service.service';

const serviceService = new ServiceService();

export class ServiceController {
  async getMerchantServices(req: Request, res: Response): Promise<void> {
    try {
      // 🛠️ Fixed: Enforced type conversion to absolute string
      const merchantId = String(req.params.merchantId);
      
      const data = await serviceService.fetchMerchantServices(merchantId);
      res.status(200).json({ success: true, data });
    } catch (error: any) {
      res.status(500).json({ success: false, message: error.message });
    }
  }

  async createServiceItem(req: Request, res: Response): Promise<void> {
    try {
      const item = await serviceService.createServiceItem(req.body);
      res.status(201).json({ success: true, data: item });
    } catch (error: any) {
      res.status(400).json({ success: false, message: error.message });
    }
  }

  async createPricingMatrix(req: Request, res: Response): Promise<void> {
    try {
      const matrix = await serviceService.createPricingMatrix(req.body);
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
      await serviceService.deletePricingMatrix(Number(id));
      res.status(200).json({ success: true, message: 'Matrix configuration purged successfully.' });
    } catch (error: any) {
      res.status(400).json({ success: false, message: error.message });
    }
  }
}