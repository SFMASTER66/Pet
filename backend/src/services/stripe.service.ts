import path from 'path';
import dotenv from 'dotenv';
import Stripe from 'stripe';

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

if (!process.env.STRIPE_SECRET_KEY) {
  throw new Error("❌ CRITICAL ERROR: STRIPE_SECRET_KEY is missing from your .env file!");
}

// ⚡ Recommended: Let the SDK manage its own API versioning
export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

export class StripeService {
  /**
   * Creates a PaymentIntent for native mobile Flutter Integration
   */
  async createPaymentIntent(params: {
    amountCents: number;
    currency: string;
    customerEmail: string;
    merchantId: string;
    appointmentId?: string;
  }) {
    try {
      const paymentIntentOptions: Stripe.PaymentIntentCreateParams = {
        amount: params.amountCents,
        currency: params.currency.toLowerCase(),
        receipt_email: params.customerEmail,
        automatic_payment_methods: {
          enabled: true,
        },
        metadata: {
          merchantId: params.merchantId,
          customerEmail: params.customerEmail,
          appointmentId: params.appointmentId || '',
        },
      };

      return await stripe.paymentIntents.create(paymentIntentOptions);
    } catch (error: any) {
      throw new Error(`Payment processing failed: ${error.message || 'Unknown error'}`);
    }
  }
}