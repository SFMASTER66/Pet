import { Router } from 'express';
import { handleContactForm, handleCareerForm } from '../controllers/customer.controller';

const router = Router();

// Public Customer Facing Contact Form Submission Entry Point
router.post('/customers/contact', handleContactForm);

// New Public Customer Facing Career Form Submission Entry Point
router.post('/customers/career', handleCareerForm);

export default router;