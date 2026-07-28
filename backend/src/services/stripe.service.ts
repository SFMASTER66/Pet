import path from 'path';
import dotenv from 'dotenv';
import Stripe from 'stripe';

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

if (!process.env.STRIPE_SECRET_KEY) {
  throw new Error("❌ CRITICAL ERROR: STRIPE_SECRET_KEY is missing from your .env file!");
}

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

export class StripeService {
  /**
   * Helper function to convert country names to ISO 3166-1 alpha-2 codes
   */
  private getCountryIsoCode(countryName: string): string {
    const countryMap: Record<string, string> = {
      'Australia': 'AU',
      'New Zealand': 'NZ',
      'United States': 'US',
      'United Kingdom': 'GB',
      'Canada': 'CA',
    };
    return countryMap[countryName] || 'AU';
  }

  /**
   * Creates or gets a Stripe Customer and generates a PaymentIntent
   */
  async createPaymentIntent(params: {
    amountCents: number;
    currency: string;
    customerEmail: string;
    customerName?: string;
    customerPhone?: string;
    customerCountry?: string;
    merchantId: string;
    appointmentId?: string;
  }) {
    try {
      const countryIsoCode = this.getCountryIsoCode(params.customerCountry || 'Australia');

      // 1. Search for existing customer or create a new one
      let customer: Stripe.Customer;
      const existingCustomers = await stripe.customers.list({
        email: params.customerEmail,
        limit: 1,
      });

      if (existingCustomers.data.length > 0) {
        // Update customer details if provided
        customer = await stripe.customers.update(existingCustomers.data[0].id, {
          name: params.customerName || existingCustomers.data[0].name || undefined,
          phone: params.customerPhone || existingCustomers.data[0].phone || undefined,
          address: {
            country: countryIsoCode,
          },
        });
      } else {
        // Create new customer
        customer = await stripe.customers.create({
          email: params.customerEmail,
          name: params.customerName,
          phone: params.customerPhone,
          address: {
            country: countryIsoCode,
          },
        });
      }

      // 2. Create PaymentIntent linked to the Customer
      const paymentIntentOptions: Stripe.PaymentIntentCreateParams = {
        amount: params.amountCents,
        currency: params.currency.toLowerCase(),
        customer: customer.id, // Attach customer ID so details appear in Stripe Dashboard
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