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
export const requestLogger = (req: LoggedRequest, res: Response, next: NextFunction) => {
  res.on('finish', () => {
    // Run async logic inside an immediately executed function with .catch() to avoid unhandled rejections
    (async () => {
      // 1. Resolve merchantId from authenticated user, body, or URL params
      const merchantId = 
        req.user?.merchantId || 
        (req.body?.merchantId as string) || 
        (req.params?.merchantId as string);

      // Skip logging if no merchant context can be identified
      if (!merchantId) return;

      // 2. Scrub sensitive data safely
      const payload = req.body ? { ...req.body } : {};
      delete payload.password;
      delete payload.passwordHash;
      delete payload.token;

      // 3. Fallback defaults for unconfigured routes so every user request gets logged
      const category = req.logConfig?.category ?? (req.path.includes('/auth') ? 'AUTH' : 'ACTIVITY');
      const moduleName = req.logConfig?.moduleName ?? 'SYSTEM_ROUTE';
      const action = req.logConfig?.action ?? `${req.method}_SUBMISSION`;
      const description = req.logConfig?.description ?? `User executed API endpoint: ${req.path}`;

      await ActivityLogService.createLog({
        merchantId,
        userId: req.user?.userId,
        category,
        moduleName,
        action,
        description,
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
    })().catch((err) => {
      console.error('Failed to save activity log:', err);
    });
  });

  next();
};