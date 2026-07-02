import { Router } from 'express';
import { ServiceController } from '../controllers/service.controller';
// import { authenticateToken, requireAdmin } from '../middlewares/auth.middleware'; // Optional auth guards

const router = Router();
const controller = new ServiceController();

// Public / Client and Merchant shared routes
router.get('/merchant/:merchantId', controller.getMerchantServices);

// Admin / Corporate Management routes
router.post('/item', controller.createServiceItem);
router.post('/matrix', controller.createPricingMatrix);
router.put('/matrix/:id', controller.updatePricingMatrix);
router.delete('/matrix/:id', controller.deletePricingMatrix);

export default router;