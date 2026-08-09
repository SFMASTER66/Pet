import { Request, Response } from 'express';
import { CustomerService } from '../services/customer.service';

/**
 * POST /api/customers/contact
 * Processes customer frontend contact forms and sends email inquiries
 */
export const handleContactForm = async (req: Request, res: Response): Promise<void> => {
  try {
    const { merchantId, firstName, lastName, email, message } = req.body;

    if (!firstName || !lastName || !email || !message) {
      res.status(400).json({
        success: false,
        message: 'Missing core criteria: mandatory contact form fields incomplete.',
      });
      return;
    }

    const payload = await CustomerService.processContactInquiry({
      merchantId,
      firstName,
      lastName,
      email,
      message,
    });

    res.status(201).json(payload);
  } catch (error: any) {
    res.status(422).json({
      success: false,
      message: error.message || 'Unprocessable transactional logic handling errors discovered on mail payload.',
    });
  }
};

/**
 * POST /api/customers/career
 * Processes frontend application submissions for job openings
 */
export const handleCareerForm = async (req: Request, res: Response): Promise<void> => {
  try {
    const { merchantId, firstName, lastName, email, message } = req.body;

    if (!firstName || !lastName || !email || !message) {
      res.status(400).json({
        success: false,
        message: 'Missing core criteria: mandatory career application fields incomplete.',
      });
      return;
    }

    const payload = await CustomerService.processCareerApplication({
      merchantId,
      firstName,
      lastName,
      email,
      message,
    });

    res.status(201).json(payload);
  } catch (error: any) {
    res.status(422).json({
      success: false,
      message: error.message || 'Unprocessable entity error processing corporate candidate notification structures.',
    });
  }
};