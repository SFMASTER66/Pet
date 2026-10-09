import { Resend } from 'resend';
import { getCareerEmailOptions } from '../email-templates/career-email';
import { getContactEmailOptions } from '../email-templates/contact-email';

// Initialize Resend Client
const resend = new Resend(process.env.RESEND_API_KEY || process.env.SMTP_PASS);

// Strict Type Definitions
interface CustomerContactInput {
  merchantId: string;
  firstName: string;
  lastName: string;
  email: string;
  message: string;
}

interface CareerApplicationInput {
  merchantId: string;
  firstName: string;
  lastName: string;
  email: string;
  message: string;
}

export const CustomerService = {
  /**
   * ✉️ Processes incoming contact inquiries and dispatches email notifications via Resend SDK
   */
  async processContactInquiry(input: CustomerContactInput) {
    const { firstName, lastName, email, message } = input;

    if (!firstName.trim() || !lastName.trim() || !email.trim() || !message.trim()) {
      throw new Error('❌ Missing operational parameters: all mandatory form fields must be populated.');
    }

    const fullName = `${firstName.trim()} ${lastName.trim()}`;

    // Resolves email parameters utilizing the external template generator
    const mailOptions = getContactEmailOptions({
      fullName,
      email,
      message,
    });

    // Send using Resend HTTPS API SDK
    const { error } = await resend.emails.send({
      from: mailOptions.from,
      to: [mailOptions.to],
      replyTo: mailOptions.replyTo,
      subject: mailOptions.subject,
      text: mailOptions.text,
      html: mailOptions.html,
    });

    if (error) {
      console.error('❌ Resend API Error (Contact Inquiry):', error);
      throw new Error(`Failed to send contact inquiry: ${error.message}`);
    }

    return {
      success: true,
      message: 'Customer inquiries successfully compiled and dispatched to the designated corporate inbox.',
    };
  },

  /**
   * 💼 Processes incoming career application forms via Resend SDK
   */
  async processCareerApplication(input: CareerApplicationInput) {
    const { firstName, lastName, email, message } = input;

    if (!firstName.trim() || !lastName.trim() || !email.trim() || !message.trim()) {
      throw new Error('❌ Operational Failure: Application details are missing required inputs.');
    }

    const fullName = `${firstName.trim()} ${lastName.trim()}`;

    // Resolves email parameters utilizing the external dedicated template
    const mailOptions = getCareerEmailOptions({
      fullName,
      email,
      message,
    });

    // Send using Resend HTTPS API SDK
    const { error } = await resend.emails.send({
      from: mailOptions.from,
      to: [mailOptions.to],
      replyTo: mailOptions.replyTo,
      subject: mailOptions.subject,
      text: mailOptions.text,
      html: mailOptions.html,
    });

    if (error) {
      console.error('❌ Resend API Error (Career Application):', error);
      throw new Error(`Failed to send career application: ${error.message}`);
    }

    return {
      success: true,
      message: 'Application form successfully delivered to HR internal recruitment routing pipelines.',
    };
  }
};