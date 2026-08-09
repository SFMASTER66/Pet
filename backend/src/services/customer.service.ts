import nodemailer from 'nodemailer';
import { getCareerEmailOptions } from '../email-templates/career-email';
import { getContactEmailOptions } from '../email-templates/contact-email';

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

// Reusable transporter generation utility
const createTransporter = () => {
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: Number(process.env.SMTP_PORT) || 465,
    secure: Number(process.env.SMTP_PORT) === 465,
    auth: {
      user: process.env.SMTP_USER || '',
      pass: process.env.SMTP_PASS || '',
    },
  });
};

export const CustomerService = {
  /**
   * ✉️ Processes incoming contact inquiries and dispatches email notifications
   */
  async processContactInquiry(input: CustomerContactInput) {
    const { firstName, lastName, email, message } = input;

    if (!firstName.trim() || !lastName.trim() || !email.trim() || !message.trim()) {
      throw new Error('❌ Missing operational parameters: all mandatory form fields must be populated.');
    }

    const transporter = createTransporter();
    const fullName = `${firstName.trim()} ${lastName.trim()}`;

    // Resolves email parameters utilizing the newly extracted external template file
    const mailOptions = getContactEmailOptions({
      fullName,
      email,
      message,
    });

    await transporter.sendMail(mailOptions);

    return {
      success: true,
      message: 'Customer inquiries successfully compiled and dispatched to the designated corporate inbox.',
    };
  },

  /**
   * 💼 Processes incoming career application forms and handles the unique template content structure
   */
  async processCareerApplication(input: CareerApplicationInput) {
    const { firstName, lastName, email, message } = input;

    if (!firstName.trim() || !lastName.trim() || !email.trim() || !message.trim()) {
      throw new Error('❌ Operational Failure: Application details are missing required inputs.');
    }

    const transporter = createTransporter();
    const fullName = `${firstName.trim()} ${lastName.trim()}`;

    // Resolves email parameters utilizing the external dedicated template
    const mailOptions = getCareerEmailOptions({
      fullName,
      email,
      message,
    });

    await transporter.sendMail(mailOptions);

    return {
      success: true,
      message: 'Application form successfully delivered to HR internal recruitment routing pipelines.',
    };
  }
};