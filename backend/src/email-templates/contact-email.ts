export interface ContactEmailData {
  fullName: string;
  email: string;
  message: string;
}

export const getContactEmailOptions = (data: ContactEmailData) => {
  const cleanEmail = data.email.trim().toLowerCase();
  
  return {
    from: `"Pawparazzi Salon System" <no-reply@pawparazzipet.com.au>`,
    to: process.env.BUSINESS_CONTACT_EMAIL || 'contact@pawparazzipet.com.au',
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
  };
};