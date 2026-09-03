import { Router } from 'express';
import { handleContactForm, handleCareerForm } from '../controllers/customer.controller';
import { requestLogger } from '../middlewares/activity-log.middleware';

const router = Router();

// Public Customer Facing Contact Form Submission Entry Point
router.post('/customers/contact', requestLogger as any, handleContactForm);

// New Public Customer Facing Career Form Submission Entry Point
router.post('/customers/career', requestLogger as any, handleCareerForm);

export default router;