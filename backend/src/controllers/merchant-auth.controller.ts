import { Request, Response } from 'express';
import { MerchantAuthService } from '../services/merchant-auth.service';
import { UserRole } from '@prisma/client';

export const registerMerchantWorkspace = async (req: Request, res: Response) => {
  try {
    const { email, password, businessName, adminName, logoIcon, primaryColor, tags } = req.body;

    if (!email || !password || !businessName || !adminName) {
      return res.status(400).json({
        success: false,
        message: 'Missing mandatory fields: email, password, businessName, and adminName are required.'
      });
    }

    const registrationPayload = await MerchantAuthService.registerMerchant({
      email,
      passwordRaw: password,
      businessName,
      adminName,
      logoIcon,
      primaryColor: primaryColor !== undefined ? String(primaryColor) : undefined,
      tags,
      role: UserRole.MERCHANT_ADMIN 
    });

    return res.status(201).json(registrationPayload);
  } catch (error: any) {
    return res.status(400).json({ success: false, message: error.message });
  }
};

export const loginMerchantWorkspace = async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password fields are required.'
      });
    }

    const loginPayload = await MerchantAuthService.loginMerchant(email, password);
    return res.status(200).json(loginPayload);
  } catch (error: any) {
    return res.status(401).json({ success: false, message: error.message });
  }
};

export const forgotPassword = async (req: Request, res: Response) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ success: false, message: 'Email field is required.' });
    }
    const payload = await MerchantAuthService.requestPasswordReset(email);
    return res.status(200).json(payload);
  } catch (error: any) {
    // Return 200/400 carefully based on privacy configurations
    return res.status(400).json({ success: false, message: error.message });
  }
};

export const resetPassword = async (req: Request, res: Response) => {
  try {
    const { token, password } = req.body;
    if (!token || !password) {
      return res.status(400).json({ success: false, message: 'Token and new password are required.' });
    }
    const payload = await MerchantAuthService.resetPassword(token, password);
    return res.status(200).json(payload);
  } catch (error: any) {
    return res.status(400).json({ success: false, message: error.message });
  }
};