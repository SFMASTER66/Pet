import { Router, Response, NextFunction } from 'express'; // <-- Ensure Response is imported here
import { 
  registerMerchantWorkspace, 
  loginMerchantWorkspace, 
  forgotPassword, 
  resetPassword 
} from '../controllers/merchant-auth.controller';
import { requireAdmin, requireRole } from '../middlewares/auth.middleware';
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
  getScheduledShifts,
  uploadMerchantLogo
} from '../controllers/merchant.controller';
import { requestLogger, LoggedRequest } from '../middlewares/activity-log.middleware';
import { UserRole } from '@prisma/client';
import multer from 'multer';

const router = Router();
const upload = multer({ 
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB limit
});

router.post('/register', requestLogger as any,registerMerchantWorkspace);
router.post('/login', requestLogger as any, loginMerchantWorkspace);
router.post('/forgot-password', requestLogger as any, forgotPassword);
router.post('/reset-password', requestLogger as any, resetPassword);

router.get('/:merchantId/dashboard', getMerchantDashboard);

router.get('/merchant/:merchantId/customers', requireAdmin as any, getPaginatedCustomersList as any);

// Protected Staff Management API Operations
router.get('/merchant/staff', requireRole([UserRole.MERCHANT_ADMIN, UserRole.MERCHANT_STAFF]), getStaffDirectory);
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
router.delete('/merchant/staff/:staffId', requireAdmin as any, requestLogger as any, deleteStaffProfile);

router.get('/merchant/:merchantId/hours', fetchMerchantHours as any);
router.put('/merchant/:merchantId/hours', requireAdmin as any, requestLogger as any, updateMerchantHoursDay as any);

// =========================================================================
// 🔥 ROSTER SCHEDULING MANAGEMENT ENDPOINTS
// =========================================================================
// router.get('/merchant/:merchantId/active-staff', requireAdmin as any, getActiveStaffDirectory as any);
router.post('/merchant/:merchantId/shifts/batch', requireAdmin as any, requestLogger as any, batchSyncShifts as any);
// router.post('/merchant/:merchantId/shifts/initialize', requireAdmin as any, initializeDefaultShifts as any);
// 🟢 NEW: Route to retrieve existing schedule assignments
router.get('/merchant/:merchantId/shifts', requireAdmin as any, getScheduledShifts as any);

router.post(
  '/merchant/:merchantId/logo',
  requireAdmin as any,
  requestLogger as any,
  upload.single('logo'),
  uploadMerchantLogo
);

export default router;