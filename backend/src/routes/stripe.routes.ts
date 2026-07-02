import express, { Router } from 'express';
import { handleStripeWebhook } from '../controllers/stripe.controller';

const router = Router();

// We inject express.raw directly into this specific route definition
router.post(
  '/stripe/webhook',
  express.raw({ type: 'application/json' }), 
  handleStripeWebhook
);

export default router;