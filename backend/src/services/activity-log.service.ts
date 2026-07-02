import { PrismaClient, LogCategory, HttpMethod } from '@prisma/client';
import prisma from './db';

export interface CreateLogInput {
  merchantId: string;
  userId?: string;
  category?: LogCategory;
  moduleName: string;
  action: string;
  description?: string;
  ipAddress?: string;
  userAgent?: string;
  path?: string;
  method?: HttpMethod;
  metaData?: any;
}

export class ActivityLogService {
  /**
   * Creates a structured audit or activity log entry
   */
  static async createLog(data: CreateLogInput) {
    try {
      return await prisma.activityLog.create({
        data: {
          merchantId: data.merchantId,
          userId: data.userId || null,
          category: data.category ?? 'ACTIVITY',
          moduleName: data.moduleName,
          action: data.action,
          description: data.description,
          ipAddress: data.ipAddress,
          userAgent: data.userAgent,
          path: data.path,
          method: data.method,
          metaData: data.metaData ? JSON.parse(JSON.stringify(data.metaData)) : undefined,
        },
      });
    } catch (error) {
      // Gracefully catch logging errors so it doesn't break core business transactions
      console.error('Failed to write activity log:', error);
    }
  }

  /**
   * Fetch logs for a specific merchant with pagination
   */
  static async getMerchantLogs(merchantId: string, limit = 50, page = 1) {
    const skip = (page - 1) * limit;
    return await prisma.activityLog.findMany({
      where: { merchantId },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip,
      include: {
        user: {
          select: { name: true, email: true, role: true },
        },
      },
    });
  }
}