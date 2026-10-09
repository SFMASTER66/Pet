import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY || process.env.SMTP_PASS);
const defaultSender = process.env.RESEND_FROM_EMAIL || 'contact@pawparazzipet.com.au';

export interface ContactEmailData {
  fullName: string;
  email: string;
  message: string;
}

export const sendContactEmail = async (data: ContactEmailData) => {
  const cleanEmail = data.email.trim().toLowerCase();
  
  return await resend.emails.send({
    from: `Pawparazzi Salon System <${defaultSender}>`,
    to: [process.env.BUSINESS_CONTACT_EMAIL || 'contact@pawparazzipet.com.au'],
    replyTo: cleanEmail,
    subject: `🚨 New Customer Inquiry from ${data.fullName}`,
    text: `
      New Contact Form Submission received:

      Customer Name: ${data.fullName}
      Email Address: ${cleanEmail}

      Message content:
      ------------------------------------------
      ${data.message.trim()}
      ------------------------------------------
    `,
    html: `
      <h3>New Contact Form Submission Received</h3>
      <p><strong>Customer Name:</strong> ${data.fullName}</p>
      <p><strong>Email Address:</strong> <a href="mailto:${cleanEmail}">${cleanEmail}</a></p>
      <br/>
      <p><strong>Message Content:</strong></p>
      <div style="padding: 12px; background-color: #f7f9fa; border-left: 4px solid #5E6D55;">
        ${data.message.trim().replace(/\n/g, '<br/>')}
      </div>
    `,
  });
};