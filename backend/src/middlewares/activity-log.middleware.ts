import { Request, Response, NextFunction } from 'express';
import { ActivityLogService } from '../services/activity-log.service';
import { HttpMethod, LogCategory, UserRole } from '@prisma/client';

// Align this with your actual AuthenticatedRequest interface
export interface LoggedRequest extends Request {
  logConfig?: {
    moduleName: string;
    action: string;
    category?: LogCategory;
    description?: string;
  };
  user?: {
    userId: string;     // Changed from 'id' to 'userId' to match auth.middleware.ts
    merchantId: string;
    role: UserRole;
  };
}

/**
 * Global or route-specific middleware that logs HTTP mutations dynamically 
 */
export const requestLogger = async (req: LoggedRequest, res: Response, next: NextFunction) => {
  // Capture response termination to track logging after processing is finished
  res.on('finish', async () => {
    if (!req.logConfig && !req.path.includes('/auth')) return;

    // Fallback to body context if the route is an unauthenticated login/register request
    const merchantId = req.user?.merchantId || (req.body.merchantId as string);
    if (!merchantId) return;

    // Scrub sensitive credentials out of the metadata payload
    const payload = { ...req.body };
    if (payload.password) delete payload.password;
    if (payload.passwordHash) delete payload.passwordHash;

    await ActivityLogService.createLog({
      merchantId,
      userId: req.user?.userId, // Map req.user.userId correctly here
      category: req.logConfig?.category ?? (req.path.includes('/auth') ? 'AUTH' : 'ACTIVITY'),
      moduleName: req.logConfig?.moduleName ?? 'SYSTEM_ROUTE',
      action: req.logConfig?.action ?? `${req.method}_SUBMISSION`,
      description: req.logConfig?.description ?? `User executed API endpoint: ${req.path}`,
      ipAddress: req.ip || req.socket.remoteAddress,
      userAgent: req.get('User-Agent'),
      path: req.path,
      method: req.method as HttpMethod,
      metaData: {
        statusCode: res.statusCode,
        query: req.query,
        body: payload,
      },
    });
  });

  next();
};