export interface CareerEmailData {
  fullName: string;
  email: string;
  message: string;
}

export const getCareerEmailOptions = (data: CareerEmailData) => {
  const cleanEmail = data.email.trim().toLowerCase();
  
  return {
    from: `"Pawparazzi Salon System" <no-reply@pawparazzipet.com.au>`,
    to: process.env.BUSINESS_CONTACT_EMAIL || 'contact@pawparazzipet.com.au',
    replyTo: cleanEmail,
    subject: `💼 New Job Application: Pet Groomer Extraordinaire - ${data.fullName}`,
    text: `
      New Career Application Received:

      Applicant Name: ${data.fullName}
      Email Address: ${cleanEmail}

      Cover Letter / Message:
      ------------------------------------------
      ${data.message.trim()}
      ------------------------------------------
    `,
    html: `
      <div style="font-family: Arial, sans-serif; color: #2C352E; max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-top: 6px solid #5E6D55; padding: 24px;">
        <h2 style="color: #5E6D55; margin-top: 0;">New Career Application</h2>
        <p>A new candidate has submitted an application for the <strong>Pet Groomer</strong> position via the Career Page.</p>
        <hr style="border: 0; border-top: 1px solid #eeeeee; margin: 20px 0;"/>
        <p><strong>Applicant Name:</strong> ${data.fullName}</p>
        <p><strong>Email Address:</strong> <a href="mailto:${cleanEmail}" style="color: #5E6D55;">${cleanEmail}</a></p>
        <br/>
        <p><strong>Cover Letter & Message:</strong></p>
        <div style="padding: 16px; background-color: #f7f9fa; border-left: 4px solid #5E6D55; font-style: italic; white-space: pre-line;">
          ${data.message.trim()}
        </div>
      </div>
    `,
  };
};