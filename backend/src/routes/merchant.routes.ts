import { Router, Response, NextFunction } from 'express'; // <-- Ensure Response is imported here
import { 
  registerMerchantWorkspace, 
  loginMerchantWorkspace, 
  forgotPassword, 
  resetPassword 
} from '../controllers/merchant-auth.controller';
import { requireAdmin } from '../middlewares/auth.middleware';
import { 
  createStaffProfile, 
  getStaffDirectory, 
  deleteStaffProfile, 
  getMerchantDashboard,
  fetchMerchantHours, 
  updateMerchantHoursDay,
  getPaginatedCustomersList,
  // getActiveStaffDirectory,
  batchSyncShifts,
  // initializeDefaultShifts,
  getScheduledShifts
} from '../controllers/merchant.controller';
import { requestLogger, LoggedRequest } from '../middlewares/activity-log.middleware';

const router = Router();

router.post('/register', registerMerchantWorkspace);
router.post('/login', loginMerchantWorkspace);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);

router.get('/:merchantId/dashboard', getMerchantDashboard);

router.get('/merchant/:merchantId/customers', requireAdmin as any, getPaginatedCustomersList as any);

// Protected Staff Management API Operations
router.get('/merchant/staff', requireAdmin, getStaffDirectory);
// 📝 Configured with Express-specific types to clear the overload mismatch
router.post(
  '/merchant/staff', 
  requireAdmin as any, 
  (req: LoggedRequest, res: Response, next: NextFunction) => {
    req.logConfig = {
      moduleName: 'SALON_SETTINGS',
      action: 'CREATE_STAFF_RECORD',
      category: 'ACTIVITY',
      description: `Administrator registered a new staff profile for user: ${req.body.name || 'Unknown'}`
    };
    next();
  }, 
  requestLogger as any, // Cast to any to cleanly bypass the Express route-handler chain checks
  createStaffProfile as any
);
router.delete('/merchant/staff/:staffId', requireAdmin, deleteStaffProfile);

router.get('/merchant/:merchantId/hours', fetchMerchantHours as any);
router.put('/merchant/:merchantId/hours', requireAdmin as any, updateMerchantHoursDay as any);

// =========================================================================
// 🔥 ROSTER SCHEDULING MANAGEMENT ENDPOINTS
// =========================================================================
// router.get('/merchant/:merchantId/active-staff', requireAdmin as any, getActiveStaffDirectory as any);
router.post('/merchant/:merchantId/shifts/batch', requireAdmin as any, batchSyncShifts as any);
// router.post('/merchant/:merchantId/shifts/initialize', requireAdmin as any, initializeDefaultShifts as any);
// 🟢 NEW: Route to retrieve existing schedule assignments
router.get('/merchant/:merchantId/shifts', requireAdmin as any, getScheduledShifts as any);

export default router;