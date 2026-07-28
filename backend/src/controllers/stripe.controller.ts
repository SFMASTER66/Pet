import { Request, Response } from 'express';
import Stripe from 'stripe';
import prisma from '../services/db';
import { StripeService, stripe } from '../services/stripe.service';

const stripeService = new StripeService();

export const createPaymentIntent = async (req: Request, res: Response): Promise<void> => {
  try {
    const { 
      amountCents, 
      currency, 
      customerEmail, 
      customerName, 
      customerPhone, 
      customerCountry, 
      merchantId, 
      appointmentId 
    } = req.body;

    if (!amountCents || !customerEmail || !merchantId) {
      res.status(400).json({ success: false, message: 'Missing required payment payload fields.' });
      return;
    }

    const intent = await stripeService.createPaymentIntent({
      amountCents,
      currency: currency || 'aud',
      customerEmail,
      customerName,
      customerPhone,
      customerCountry,
      merchantId,
      appointmentId,
    });

    res.status(200).json({
      success: true,
      clientSecret: intent.client_secret,
      paymentIntentId: intent.id,
    });
  } catch (err: any) {
    console.error(`❌ PaymentIntent Creation Failed: ${err.message}`);
    res.status(500).json({ success: false, message: err.message });
  }
};

export const handleStripeWebhook = async (req: Request, res: Response): Promise<void> => {
  const sig = req.headers['stripe-signature'];
  const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET!;

  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig!, endpointSecret);
  } catch (err: any) {
    console.error(`❌ Webhook signature verification failed: ${err.message}`);
    res.status(400).send(`Webhook Error: ${err.message}`);
    return;
  }

  switch (event.type) {
    case 'payment_intent.succeeded': {
      const paymentIntent = event.data.object as Stripe.PaymentIntent;
      const appointmentId = paymentIntent.metadata?.appointmentId;

      console.log(`💰 Payment succeeded for PaymentIntent [${paymentIntent.id}], Appointment [${appointmentId}]`);

      if (appointmentId) {
        await prisma.appointment.update({
          where: { id: appointmentId },
          data: { status: 'PAID' },
        });
      }
      break;
    }

    case 'payment_intent.payment_failed': {
      const paymentIntent = event.data.object as Stripe.PaymentIntent;
      const appointmentId = paymentIntent.metadata?.appointmentId;

      console.log(`❌ Payment failed for PaymentIntent [${paymentIntent.id}], Appointment [${appointmentId}]`);

      if (appointmentId) {
        await prisma.appointment.update({
          where: { id: appointmentId },
          data: { status: 'CANCELLED' },
        });
      }
      break;
    }

    default:
      console.log(`ℹ️ Unhandled Stripe event type: ${event.type}`);
  }

  res.json({ received: true });
};