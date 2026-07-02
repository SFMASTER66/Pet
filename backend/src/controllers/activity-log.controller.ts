import { Response } from 'express';
import { LoggedRequest } from '../middlewares/activity-log.middleware';
import { ActivityLogService } from '../services/activity-log.service';

export class ActivityLogController {
  /**
   * GET /api/v1/logs
   * Retrieves paginated activity logs for a specific salon account
   */
  static async getLogs(req: LoggedRequest, res: Response): Promise<void> {
    try {
      const merchantId = req.user?.merchantId;
      if (!merchantId) {
        res.status(400).json({ error: 'Merchant context validation failed' });
        return;
      }

      const limit = parseInt(req.query.limit as string) || 50;
      const page = parseInt(req.query.page as string) || 1;

      const logs = await ActivityLogService.getMerchantLogs(merchantId, limit, page);
      res.status(200).json({ success: true, data: logs });
    } catch (error: any) {
      res.status(500).json({ error: 'Internal Server Error', details: error.message });
    }
  }
}