import nodemailer from 'nodemailer';
import { getCareerEmailOptions } from '../email-templates/career-email';

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

    const mailOptions = {
      from: `"Pawparazzi Salon System" <no-reply@pawparazzipet.com.au>`,
      to: process.env.BUSINESS_CONTACT_EMAIL || 'contact@pawparazzipet.com.au',
      replyTo: email.trim().toLowerCase(),
      subject: `🚨 New Customer Inquiry from ${fullName}`,
      text: `
        New Contact Form Submission received:
        Customer Name: ${fullName}
        Email Address: ${email.trim().toLowerCase()}
        Message content:
        ${message.trim()}
      `,
      html: `
        <h3>New Contact Form Submission Received</h3>
        <p><strong>Customer Name:</strong> ${fullName}</p>
        <p><strong>Email Address:</strong> <a href="mailto:${email.trim().toLowerCase()}">${email.trim().toLowerCase()}</a></p>
        <br/>
        <p><strong>Message Content:</strong></p>
        <div style="padding: 12px; background-color: #f7f9fa; border-left: 4px solid #5E6D55;">
          ${message.trim().replace(/\n/g, '<br/>')}
        </div>
      `,
    };

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