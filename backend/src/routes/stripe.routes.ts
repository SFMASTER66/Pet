import express, { Router } from 'express';
import { createPaymentIntent, handleStripeWebhook } from '../controllers/stripe.controller';
import { requestLogger } from '../middlewares/activity-log.middleware';

const router = Router();

// Create PaymentIntent route for Flutter app
router.post('/payments/create-intent', express.json(), requestLogger as any, createPaymentIntent);

// Raw Body Webhook Route for Stripe Signatures Verification
router.post(
  '/stripe/webhook',
  express.raw({ type: 'application/json' }), 
  requestLogger as any,
  handleStripeWebhook
);

export default router;