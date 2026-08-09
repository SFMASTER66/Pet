import { Router } from 'express';
import { handleContactForm } from '../controllers/customer.controller';

const router = Router();

// Public Customer Facing Contact Form Submission Entry Point
router.post('/customers/contact', handleContactForm);

export default router;