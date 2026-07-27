import express, { Router } from 'express';
import { createPaymentIntent, handleStripeWebhook } from '../controllers/stripe.controller';

const router = Router();

// Create PaymentIntent route for Flutter app
router.post('/payments/create-intent', express.json(), createPaymentIntent);

// Raw Body Webhook Route for Stripe Signatures Verification
router.post(
  '/stripe/webhook',
  express.raw({ type: 'application/json' }), 
  handleStripeWebhook
);

export default router;