import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/auth.middleware';
import { MerchantService } from '../services/merchant.service';
import { LoggedRequest } from '../middlewares/activity-log.middleware';

const merchantService = new MerchantService();

export const getMerchantDashboard = async (req: any, res: Response) => {
  try {
    const merchantId = (req.get('merchantId') || req.params.merchantId) as string;
    if (!merchantId) {
      return res.status(400).json({ success: false, message: 'Merchant ID is required.' });
    }
    const dashboardData = await merchantService.getDashboardData(merchantId);
    return res.json({ success: true, data: dashboardData });
  } catch (error: any) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

export const getStaffDirectory = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const adminUser = req.user;
    if (!adminUser || !adminUser.merchantId) {
      return res.status(401).json({ success: false, message: 'Unauthorized execution framework.' });
    }
    const list = await merchantService.getMerchantStaff(adminUser.merchantId);
    return res.status(200).json({ success: true, data: list });
  } catch (error: any) {
    return res.status(400).json({ success: false, message: error.message });
  }
};

export const createStaffProfile = async (req: LoggedRequest, res: Response) => {
  try {
    const { name, email, password } = req.body;
    const adminUser = req.user; 

    if (!adminUser || !adminUser.merchantId) {
      return res.status(401).json({ success: false, message: 'Unauthorized session context.' });
    }

    if (!name || !email || !password) {
      return res.status(400).json({ success: false, message: 'Missing required fields.' });
    }

    const newStaff = await merchantService.addStaffAccount({
      name,
      email,
      passwordRaw: password,
      merchantId: adminUser.merchantId
    });

    return res.status(201).json({ 
      success: true, 
      message: 'Staff profile created successfully.', 
      data: newStaff 
    });
  } catch (error: any) {
    return res.status(400).json({ success: false, message: error.message });
  }
};

export const deleteStaffProfile = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { staffId } = req.params;
    const adminUser = req.user;

    const { isActive } = req.body;

    // 1. Guard check: Ensure adminUser and merchantId exist
    if (!adminUser || !adminUser.merchantId) {
      return res.status(401).json({ 
        success: false, 
        message: 'Unauthorized operational engine matrix context.' 
      });
    }

    // 2. Safely resolve the staffId type to a single string
    const safeStaffId = Array.isArray(staffId) ? staffId[0] : staffId;

    if (!safeStaffId) {
      return res.status(400).json({
        success: false,
        message: 'Valid Staff ID is required parameter.'
      });
    }

    if (isActive === undefined) {
      return res.status(400).json({
        success: false,
        message: 'The isActive flag is required.'
      });
    }

    // 3. Execute with guaranteed string parameters
    await merchantService.removeStaffAccount(safeStaffId, adminUser.merchantId, isActive);
    
    return res.status(200).json({ 
      success: true, 
      message: 'Staff context record dropped successfully.' 
    });
  } catch (error: any) {
    return res.status(400).json({ success: false, message: error.message });
  }
};

export const fetchMerchantHours = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { merchantId } = req.params;
    
    // Security Context Enforcement Guard Rule
    if (!req.user || req.user.merchantId !== merchantId) {
      return res.status(401).json({ success: false, message: 'Unauthorized merchant domain boundary context.' });
    }

    const hours = await merchantService.getBusinessHours(merchantId);
    return res.status(200).json({ success: true, data: hours });
  } catch (error: any) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

export const updateMerchantHoursDay = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { merchantId } = req.params;
    const { dayOfWeek, openTime, closeTime, isClosed } = req.body;

    // Security context validation guard check
    if (!req.user || req.user.merchantId !== merchantId) {
      return res.status(401).json({ success: false, message: 'Unauthorized operational modification frame.' });
    }

    if (!dayOfWeek || !openTime || !closeTime || isClosed === undefined) {
      return res.status(400).json({ success: false, message: 'Missing explicit day structural boundary components.' });
    }

    const updatedDay = await merchantService.upsertBusinessHoursDay(
      merchantId,
      Number(dayOfWeek),
      openTime,
      closeTime,
      isClosed
    );

    return res.status(200).json({ success: true, data: updatedDay });
  } catch (error: any) {
    return res.status(500).json({ success: false, message: error.message });
  }
};