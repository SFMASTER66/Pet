import { Router } from 'express';
import { registerMerchantWorkspace, loginMerchantWorkspace  } from '../controllers/merchant-auth.controller';
import { requireAdmin } from '../middlewares/auth.middleware';
import { 
  createStaffProfile, 
  getStaffDirectory, 
  deleteStaffProfile, 
  getMerchantDashboard 
} from '../controllers/merchant.controller';

const router = Router();

router.post('/register', registerMerchantWorkspace);
router.post('/login', loginMerchantWorkspace);
router.get('/:merchantId/dashboard', getMerchantDashboard);

// Protected Staff Management API Operations
router.get('/merchant/staff', requireAdmin, getStaffDirectory);
router.post('/merchant/staff', requireAdmin, createStaffProfile);
router.delete('/merchant/staff/:staffId', requireAdmin, deleteStaffProfile);

export default router;