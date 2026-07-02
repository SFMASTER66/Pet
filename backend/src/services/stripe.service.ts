import Stripe from 'stripe';

// 这里的私钥以后存放在 .env 文件中
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2026-06-24.dahlia', // 建议锁定版本，保证全球化稳定性
});

export class StripeService {
  /**
   * 核心功能：创建 Stripe Checkout 会话
   * 这里的关键是：我们需要把商家的 Stripe Account ID 传进去，实现自动分账
   */
  async createCheckoutSession(params: {
    amount: number;
    currency: string;
    merchantStripeAccountId: string; // 核心：多租户分账的目标账户
    appointmentId: string;
    customerEmail: string;
  }) {
    return await stripe.checkout.sessions.create({
      payment_method_types: ['card'], // 澳洲常用，也可加 apple_pay
      customer_email: params.customerEmail,
      line_items: [{
        price_data: {
          currency: params.currency,
          product_data: { name: '宠物洗护预约服务' },
          unit_amount: params.amount * 100, // Stripe 以“分”为单位，如果是 $120 需传 12000
        },
        quantity: 1,
      }],
      mode: 'payment',
      // 🌟 核心：Stripe Connect 分账逻辑
      // 这里会自动扣除你作为平台的佣金，并把剩下的钱打给商家
      payment_intent_data: {
        application_fee_amount: params.amount * 100 * 0.1, // 比如你收 10% 平台手续费
        transfer_data: {
          destination: params.merchantStripeAccountId, // 钱最终流向哪家店
        },
      },
      success_url: `${process.env.FRONTEND_URL}/booking/success?id=${params.appointmentId}`,
      cancel_url: `${process.env.FRONTEND_URL}/booking/cancel`,
    });
  }
}