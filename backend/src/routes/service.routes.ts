import { Router } from 'express';
import { ServiceController } from '../controllers/service.controller';

const router = Router();
const controller = new ServiceController();

// Shared Matrix Visibility Layer
router.get('/merchant/:merchantId', controller.getMerchantServices);

// Orchestration / Provisioning Write Blocks
router.post('/matrix', controller.createPricingMatrix);
router.put('/matrix/:id', controller.updatePricingMatrix);
router.delete('/matrix/:id', controller.deletePricingMatrix);

export default router;