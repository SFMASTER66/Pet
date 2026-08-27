export interface BookingEmailData {
  ownerName: string;
  ownerEmail: string;
  ownerPhone: string;
  dogName: string;
  dogBreed: string;
  dogWeight: number;
  dogDob?: Date | string | null;
  isDesexed: boolean;
  notes?: string | null;
  addOns?: Array<{ name?: string; priceCents?: number; quantity?: number }>;
  serviceName: string;
  weightTier?: string;
  coatCategory?: string;
  serviceTime: Date | string;
  durationMinutes: number;
  priceCentsAud: number;
  depositPaid?: boolean;
  groomerName?: string;
  merchantAddress?: string;
}

const formatDate = (dateInput: Date | string): string => {
  const dt = new Date(dateInput);
  return dt.toLocaleString('en-AU', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
    timeZoneName: 'short'
  });
};

const calculateAge = (dobInput?: Date | string | null): string => {
  if (!dobInput) return 'N/A';
  const dob = new Date(dobInput);
  if (isNaN(dob.getTime())) return 'N/A';
  const now = new Date();
  let years = now.getFullYear() - dob.getFullYear();
  let months = now.getMonth() - dob.getMonth();
  if (months < 0) {
    years--;
    months += 12;
  }
  return `${years} yrs ${months} mos`;
};

export const getOwnerBookingEmailOptions = (data: BookingEmailData) => {
  const cleanEmail = data.ownerEmail.trim().toLowerCase();
  const totalPrice = (data.priceCentsAud / 100).toFixed(2);
  const formattedDate = formatDate(data.serviceTime);
  const ageText = calculateAge(data.dogDob);

  const addOnsFormatted = data.addOns && data.addOns.length > 0
    ? data.addOns.map(a => `${a.name || 'Add-on'} ($${((a.priceCents || 0) / 100).toFixed(2)})`).join(', ')
    : 'None';

  return {
    from: `"Pawparazzi Salon System" <no-reply@pawparazzipet.com.au>`,
    to: process.env.BUSINESS_CONTACT_EMAIL || 'contact@pawparazzipet.com.au',
    replyTo: cleanEmail,
    subject: `📅 New Booking Notification: ${data.dogName} (${data.serviceName})`,
    html: `
      <div style="font-family: Arial, sans-serif; color: #2C352E; max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-top: 6px solid #5E6D55; padding: 24px; background-color: #ffffff;">
        <h2 style="color: #2C352E; margin-top: 0; font-size: 24px;">You got a new booking</h2>
        <p style="color: #555555; font-size: 14px;">Great news! Someone just booked one of your services.</p>
        
        <hr style="border: 0; border-top: 1px solid #eeeeee; margin: 20px 0;"/>

        <h3 style="color: #2C352E; font-size: 18px; margin-bottom: 12px;">Clients details</h3>

        <p style="margin: 4px 0;"><strong>Name:</strong><br/>${data.ownerName}</p>
        <p style="margin: 12px 0 4px 0;"><strong>Email:</strong><br/><a href="mailto:${cleanEmail}" style="color: #0066cc; text-decoration: none;">${cleanEmail}</a></p>
        <p style="margin: 12px 0 4px 0;"><strong>Contact number:</strong><br/>${data.ownerPhone}</p>
        
        <p style="margin: 12px 0 4px 0;"><strong>Dog's Name:</strong><br/>${data.dogName}</p>
        <p style="margin: 12px 0 4px 0;"><strong>Dog's Breed:</strong><br/>${data.dogBreed.toUpperCase()}</p>
        <p style="margin: 12px 0 4px 0;"><strong>Dog's Age:</strong><br/>${ageText}</p>
        <p style="margin: 12px 0 4px 0;"><strong>Desexed (Y/N):</strong><br/>${data.isDesexed ? 'Y' : 'N'}</p>
        
        <p style="margin: 12px 0 4px 0;"><strong>Any special requirement?:</strong><br/>${data.notes || 'None'}</p>
        <p style="margin: 12px 0 4px 0;"><strong>Add on service (extra charge):</strong><br/>${addOnsFormatted}</p>
        
        <p style="margin: 12px 0 4px 0;"><strong>I read and agree to Pawparazzi Pet Grooming policy:</strong><br/>Checked</p>
        <p style="margin: 12px 0 4px 0;"><strong>I agree to No cancellations or changes allowed within 24 hours of the appointment. Cancellation Policy:</strong><br/>Checked</p>

        <hr style="border: 0; border-top: 1px solid #eeeeee; margin: 20px 0;"/>

        <h3 style="color: #2C352E; font-size: 18px; margin-bottom: 8px;">${data.serviceName}</h3>

        <p style="margin: 12px 0 4px 0;"><strong>When:</strong><br/>${formattedDate}</p>
        <p style="margin: 12px 0 4px 0;"><strong>Location:</strong><br/>${data.merchantAddress || 'shop 64/30 Lonsdale Street, Braddon ACT, Australia'}</p>
        <p style="margin: 12px 0 4px 0;"><strong>Staff:</strong><br/>${data.groomerName || 'Assigned Staff'}</p>
        <p style="margin: 12px 0 4px 0;"><strong>Price:</strong><br/><strong>$${totalPrice} AUD</strong></p>

        <p style="margin: 12px 0 4px 0;"><strong>Service Type:</strong><br/>${data.serviceName} ($${totalPrice} AUD)</p>
      </div>
    `,
  };
};

export const getCustomerBookingEmailOptions = (data: BookingEmailData) => {
  const cleanEmail = data.ownerEmail.trim().toLowerCase();
  const totalPrice = (data.priceCentsAud / 100).toFixed(2);
  const formattedDate = formatDate(data.serviceTime);

  return {
    from: `"Pawparazzi Pet Grooming" <no-reply@pawparazzipet.com.au>`,
    to: cleanEmail,
    subject: `🐾 Booking Confirmation - Pawparazzi Pet Grooming`,
    html: `
      <div style="font-family: Arial, sans-serif; color: #2C352E; max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-top: 6px solid #5E6D55; padding: 24px; background-color: #ffffff;">
        <h2 style="color: #5E6D55; margin-top: 0;">Booking Confirmation</h2>
        <p>Hi ${data.ownerName},</p>
        <p>Thank you for booking with Pawparazzi! Your appointment for <strong>${data.dogName}</strong> has been received.</p>
        
        <hr style="border: 0; border-top: 1px solid #eeeeee; margin: 20px 0;"/>

        <h3 style="color: #2C352E;">Appointment Details</h3>
        <p><strong>Service:</strong> ${data.serviceName}</p>
        <p><strong>When:</strong> ${formattedDate}</p>
        <p><strong>Location:</strong> ${data.merchantAddress || 'shop 64/30 Lonsdale Street, Braddon ACT, Australia'}</p>
        <p><strong>Total Price:</strong> $${totalPrice} AUD</p>

        <hr style="border: 0; border-top: 1px solid #eeeeee; margin: 20px 0;"/>
        <p style="font-size: 13px; color: #777777;">If you need to reschedule, please contact us at least 24 hours prior to your scheduled time.</p>
      </div>
    `,
  };
};