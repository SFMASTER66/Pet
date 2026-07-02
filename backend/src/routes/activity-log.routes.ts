import { Router, Response, NextFunction } from 'express';
import { ActivityLogController } from '../controllers/activity-log.controller';
import { requireAdmin } from '../middlewares/auth.middleware';
import { LoggedRequest } from '../middlewares/activity-log.middleware';

const router = Router();

// Secure log querying downstream so only authenticated admins can pull data
router.get(
  '/', 
  requireAdmin as any, // Cast to any to bypass the express middleware type conflict
  (req: LoggedRequest, res: Response) => ActivityLogController.getLogs(req, res)
);

export default router;