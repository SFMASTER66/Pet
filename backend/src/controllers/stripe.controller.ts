import path from 'path';
import dotenv from 'dotenv';
import { Request, Response } from 'express';
import Stripe from 'stripe';
import prisma from '../services/db';


// Ensure environment variables are loaded for this file
dotenv.config({ path: path.resolve(process.cwd(), '.env') });

if (!process.env.STRIPE_SECRET_KEY) {
  throw new Error("❌ CRITICAL ERROR: STRIPE_SECRET_KEY is missing from your .env file!");
}

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
  apiVersion: '2025-10-16' as any, // Use your target API version
});

export const handleStripeWebhook = async (req: Request, res: Response): Promise<void> => {
  const sig = req.headers['stripe-signature'];
  const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET!;

  let event: Stripe.Event;

  try {
    // 1. Verify webhook signature using the raw body (req.body)
    event = stripe.webhooks.constructEvent(req.body, sig!, endpointSecret);
  } catch (err: any) {
    console.error(`❌ Webhook signature verification failed: ${err.message}`);
    res.status(400).send(`Webhook Error: ${err.message}`);
    return;
  }

  // 2. Handle business logic based on event type
  switch (event.type) {
    case 'checkout.session.completed': {
      const session = event.data.object as Stripe.Checkout.Session;
      const appointmentId = session.metadata?.appointmentId;

      if (appointmentId) {
        console.log(`💰 Payment success received for appointment [${appointmentId}]. Updating database...`);

        await prisma.appointment.update({
          where: { id: appointmentId },
          data: { status: 'PAID' },
        });
        
        // 🚀 Future async tasks (e.g., push notifications, sending receipt H5) go here
      }
      break;
    }

    case 'checkout.session.expired': {
      const session = event.data.object as Stripe.Checkout.Session;
      const appointmentId = session.metadata?.appointmentId;

      if (appointmentId) {
        console.log(`❌ Appointment [${appointmentId}] payment expired/cancelled. Releasing timeslot.`);
        
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

  // 3. Return 200 OK swiftly to acknowledge receipt
  res.json({ received: true });
};