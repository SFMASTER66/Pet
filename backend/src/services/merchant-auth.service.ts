import { UserRole } from '@prisma/client';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import prisma from './db';

const JWT_SECRET = process.env.JWT_SECRET || 'super-secret-petcloud-key';
const RESET_SECRET = process.env.RESET_SECRET || 'super-secret-reset-key';

export class MerchantAuthService {
  /**
   * Registers a brand-new tenant merchant along with an initial administrator account
   */
  static async registerMerchant(data: {
    email: string;
    passwordRaw: string;
    businessName: string;
    adminName: string; 
    logoIcon?: string;
    primaryColor?: string;
    tags?: string[];
    role: UserRole; 
  }) {
    const existingUser = await prisma.user.findFirst({
      where: { 
        email: data.email,
        role: data.role
      },
    });
    if (existingUser) {
      throw new Error('An administrator account with this email already exists.');
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(data.passwordRaw, salt);

    const result = await prisma.$transaction(async (tx) => {
      const merchant = await tx.merchant.create({
        data: {
          email: data.email, 
          passwordHash: hashedPassword,
          businessName: data.businessName,
          logoIcon: data.logoIcon || '',
          primaryColor: data.primaryColor ?? "0xFF0F766E",
          tags: data.tags || [],
        },
      });

      const adminUser = await tx.user.create({
        data: {
          email: data.email,
          passwordHash: hashedPassword, 
          name: data.adminName,         
          role: data.role, 
          merchantId: merchant.id,
        },
      });

      return { 
        user: adminUser, // Changed key from adminUser to user
        config: merchant // Providing a clean config mapping
      };
    },{
      timeout: 30000 
    });

    const token = jwt.sign(
      { userId: result.user.id, merchantId: result.config.id, role: result.user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    return {
      success: true,
      message: 'Merchant tenant workspace initialized successfully.',
      token,
      role: result.user.role, // 🛠️ FIX: Explicitly include the role here!
      config: {
        businessName: result.config.businessName,
        logoIcon: result.config.logoIcon,
        primaryColor: result.config.primaryColor,
        tags: result.config.tags,
        features: ['dashboard', 'bookings', 'settings', 'staff', 'billing']
      },
    };
  }

  /**
   * Authenticates an administrator or staff based purely on email validation
   */
  static async loginMerchant(email: string, passwordRaw: string) {
    // 1. Query using only email
    const user = await prisma.user.findFirst({
      where: { email },
      include: { merchant: true },
    });

    if (!user || !user.merchant) {
      throw new Error('Invalid credentials or tenant workspace missing.');
    }

    // 2. Extra safety gate check
    if (user.role !== UserRole.MERCHANT_ADMIN && user.role !== UserRole.MERCHANT_STAFF) {
      throw new Error('Access denied. Insufficient permissions.');
    }

    const isPasswordValid = await bcrypt.compare(passwordRaw, user.passwordHash); 
    if (!isPasswordValid) {
      throw new Error('Invalid credentials provided.');
    }

    const token = jwt.sign(
      { userId: user.id, merchantId: user.merchant.id, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    // 3. Conditional Feature Payload Assignment
    let features: string[] = [];
    let configurations: Record<string, any> = {};

    if (user.role === UserRole.MERCHANT_ADMIN) {
      features = ['dashboard', 'bookings', 'settings', 'staff', 'billing']; // All features
      configurations = {
        merchantId: user.merchant.id,
        businessName: user.merchant.businessName,
        logoIcon: user.merchant.logoIcon,
        primaryColor: user.merchant.primaryColor,
        tags: user.merchant.tags,
      };
    } else if (user.role === UserRole.MERCHANT_STAFF) {
      features = ['bookings']; // Staff only see bookings feature
      configurations = {
        merchantId: user.merchant.id,
        businessName: user.merchant.businessName,
        logoIcon: user.merchant.logoIcon,
        // primaryColor, tags etc. excluded/hidden for staff
      };
    }

    return {
      success: true,
      message: 'Authentication validated successfully.',
      token,
      role: user.role,
      config: {
        ...configurations,
        features
      },
    };
  }

  /**
   * Generates a password reset token if the email exists
   */
  static async requestPasswordReset(email: string) {
    const user = await prisma.user.findFirst({
      where: { email },
    });

    if (!user) {
      // Security best practice: Don't explicitly reveal if an email doesn't exist
      throw new Error('If the account exists, a recovery link has been generated.');
    }

    // Generate a secure, short-lived reset token (valid for 15 mins)
    const resetToken = jwt.sign(
      { userId: user.id, email: user.email },
      RESET_SECRET,
      { expiresIn: '15m' }
    );

    // In production, integrate Nodemailer/SendGrid here to email the token/link.
    // For this implementation, we return it so the API can pass it or log it.
    console.log(`[PASSWORD RESET TOKEN FOR ${email}]: ${resetToken}`);

    return {
      success: true,
      message: 'Password reset token generated successfully.',
      resetToken, // Returned for ease of testing/UI matching
    };
  }

  /**
   * Validates the reset token and updates the password
   */
  static async resetPassword(token: string, passwordRaw: string) {
    try {
      const decoded = jwt.verify(token, RESET_SECRET) as { userId: string; email: string };

      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(passwordRaw, salt);

      // Update password across both tables if necessary, or just the User table
      await prisma.$transaction(async (tx) => {
        await tx.user.update({
          where: { id: decoded.userId },
          data: { passwordHash: hashedPassword },
        });

        // Also sync back to merchant if this user shares the primary tenant credentials
        await tx.merchant.updateMany({
          where: { email: decoded.email },
          data: { passwordHash: hashedPassword },
        });
      });

      return {
        success: true,
        message: 'Your password has been reset successfully. Please log in.',
      };
    } catch (error) {
      throw new Error('Invalid or expired password reset token.');
    }
  }
}