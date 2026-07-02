import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { UserRole } from '@prisma/client';

const JWT_SECRET = process.env.JWT_SECRET || 'super-secret-petcloud-key';

// Extend Express Request type locally to support authenticated payloads
export interface AuthenticatedRequest extends Request {
  user?: {
    userId: string;
    merchantId: string;
    role: UserRole;
  };
}

export const requireAdmin = (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        success: false, 
        message: 'Authorization token missing or malformed.' 
      });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, JWT_SECRET) as any;

    // Strict Guard: Reject if the user is a staff member trying to add other staff
    if (decoded.role !== UserRole.MERCHANT_ADMIN) {
      return res.status(403).json({ 
        success: false, 
        message: 'Access denied. Only workspace administrators can perform this action.' 
      });
    }

    // Attach decoded user token context to request object
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ 
      success: false, 
      message: 'Invalid or expired authorization session token.' 
    });
  }
};