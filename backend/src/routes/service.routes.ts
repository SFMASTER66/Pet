import { Router, Request, Response } from 'express';
import { ServiceController } from '../controllers/service.controller';
import { MerchantService } from '../services/merchant.service';

const router = Router();
const controller = new ServiceController();
const merchantService = new MerchantService();

// Shared Matrix Visibility Layer
router.get('/merchant/:merchantId', controller.getMerchantServices);

// Orchestration / Provisioning Write Blocks
router.post('/matrix', controller.createPricingMatrix);
router.put('/matrix/:id', controller.updatePricingMatrix);
router.delete('/matrix/:id', controller.deletePricingMatrix);

// GET /api/v1/matrix?merchantId=XYZ
router.get('/matrix', async (req: Request, res: Response) => {
  try {
    const merchantId = req.query.merchantId as string;
    if (!merchantId) {
      return res.status(400).json({ success: false, message: 'Missing merchantId query parameter.' });
    }
    const matrices = await merchantService.getServiceMatrices(merchantId);
    return res.status(200).json({ success: true, data: matrices });
  } catch (error: any) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

export default router;