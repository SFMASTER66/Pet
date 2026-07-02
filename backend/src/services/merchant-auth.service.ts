import { UserRole } from '@prisma/client';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import prisma from './db';

const JWT_SECRET = process.env.JWT_SECRET || 'super-secret-petcloud-key';

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
    primaryColor?: number;
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
          primaryColor: data.primaryColor ?? 0xFF0F766E,
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

      return { merchant, adminUser };
    },{
      timeout: 30000 
    });

    const token = jwt.sign(
      { userId: result.adminUser.id, merchantId: result.merchant.id, role: result.adminUser.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    return {
      success: true,
      message: 'Merchant tenant workspace initialized successfully.',
      token,
      config: {
        businessName: result.merchant.businessName,
        logoIcon: result.merchant.logoIcon,
        primaryColor: result.merchant.primaryColor,
        tags: result.merchant.tags,
        features: ['dashboard', 'bookings', 'settings', 'staff', 'billing'] // Admins get all features
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
        businessName: user.merchant.businessName,
        logoIcon: user.merchant.logoIcon,
        primaryColor: user.merchant.primaryColor,
        tags: user.merchant.tags,
      };
    } else if (user.role === UserRole.MERCHANT_STAFF) {
      features = ['bookings']; // Staff only see bookings feature
      configurations = {
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
}