import { Request, Response } from 'express';
import { BookingService } from '../services/booking.service';
import { Gender } from '@prisma/client';
import prisma from '../services/db';
import { AppointmentStatus } from '@prisma/client';

/**
 * GET /api/bookings/services?merchantId=XYZ
 * Queries current available matrix configurations for dropdowns
 */
export const fetchDropdownServices = async (req: Request, res: Response): Promise<void> => {
  try {
    const { merchantId } = req.query;
    if (!merchantId || typeof merchantId !== 'string') {
      res.status(400).json({ success: false, message: 'Missing query parameter: merchantId criteria required.' });
      return;
    }
    const services = await BookingService.getAvailableServices(merchantId);
    res.status(200).json({ success: true, data: services });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Fatal read execution failure.' });
  }
};

/**
 * POST /api/bookings/admin-add
 * Processes administrative dashboard manual appointments forms
 */
export const portalBooking = async (req: Request, res: Response): Promise<void> => {
  try {
    const {
      merchantId,
      bookedById,
      servicePricingMatrixId,
      dogName,
      dogBreed,
      dogGender,
      isDesexed,
      dogWeight,
      dogDob,
      ownerName,
      ownerPhone,
      ownerEmail,
      serviceTime,
      groomerId,
      note
    } = req.body;

    if (!merchantId || !bookedById || !servicePricingMatrixId || !dogName || !ownerPhone || !serviceTime || !dogWeight || !dogDob) {
      res.status(400).json({
        success: false,
        message: 'Missing core criteria: mandatory fields incomplete.'
      });
      return;
    }

    const payload = await BookingService.portalBooking({
      merchantId,
      bookedById,
      servicePricingMatrixId: Number(servicePricingMatrixId),
      dogName,
      dogBreed,
      dogGender: dogGender as Gender,
      isDesexed: Boolean(isDesexed),
      dogWeight: Number(dogWeight),
      dogDob: new Date(dogDob),
      ownerName,
      ownerPhone,
      ownerEmail: ownerEmail || `${ownerPhone.replace(/\s+/g, '')}@placeholder-salon-system.com`,
      serviceTime,
      groomerId,
      note
    });

    res.status(201).json(payload);
  } catch (error: any) {
    res.status(422).json({
      success: false,
      message: error.message || 'Unprocessable transactional logic handling errors discovered.'
    });
  }
};

/**
 * PUT /api/bookings/update/:id
 * Updates administrative appointment statuses, check-in markers, and timestamps
 */
export const updateBooking = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const {
      status,
      startTime,
      isCheckedIn,
      depositPaid,
      isReadyToPickup,
      isLoyaltyWaived,
      internalTags
    } = req.body;

    if (!id) {
      res.status(400).json({ success: false, message: 'Missing target appointment tracking identifier param.' });
      return;
    }

    // Fixed error TS2345 by explicitly casting 'id' as a string parameter
    const payload = await BookingService.updateBooking(id as string, {
      status,
      startTime,
      isCheckedIn: isCheckedIn !== undefined ? Boolean(isCheckedIn) : undefined,
      depositPaid: depositPaid !== undefined ? Boolean(depositPaid) : undefined,
      isReadyToPickup: isReadyToPickup !== undefined ? Boolean(isReadyToPickup) : undefined,
      isLoyaltyWaived: isLoyaltyWaived !== undefined ? Boolean(isLoyaltyWaived) : undefined,
      internalTags: Array.isArray(internalTags) ? internalTags : undefined,
    });

    res.status(200).json(payload);
  } catch (error: any) {
    res.status(422).json({
      success: false,
      message: error.message || 'Unprocessable transactional logic handling errors encountered during modification.'
    });
  }
};

/**
 * POST /api/bookings
 * Keeps your original method safe and functional for the public customer flow
 */
export const registerBooking = async (req: Request, res: Response): Promise<void> => {
  try {
    const {
      ownerId,
      breed,
      name,
      microchipNumber,
      gender,      
      isDesexed,   
      dob,         
      behaviorTags,
      behaviorNotes,
      merchantId,
    } = req.body;

    if (!ownerId || !breed || !name) {
      res.status(400).json({
        success: false,
        message: 'Missing mandatory parameters: ownerId, breed, or name.',
      });
      return;
    }
    
    const dogSpecies = await prisma.species.findUnique({
      where: { name: 'Dog' }
    });

    if (!dogSpecies) {
      res.status(500).json({
        success: false,
        message: "System configuration fault: 'Dog' species records are missing.",
      });
      return;
    }

    const result = await BookingService.createAppointment({
      ownerId,
      speciesId: dogSpecies.id, 
      breed,
      name,
      microchipNumber,
      gender: gender as Gender, 
      isDesexed: Boolean(isDesexed), 
      dob,
      behaviorTags: behaviorTags || [],
      behaviorNotes,
      merchantId,
    });

    res.status(211).json(result);
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const removeBooking = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    if (!id) {
      res.status(400).json({ success: false, message: 'Missing mandatory route parameter: id.' });
      return;
    }

    const result = await BookingService.deleteBooking(id as string);
    res.status(200).json(result);
  } catch (error: any) {
    res.status(500).json({ 
      success: false, 
      message: error.message || 'Fatal delete execution failure.' 
    });
  }
};

export const fetchAvailableSlots = async (req: Request, res: Response): Promise<void> => {
  try {
    const { merchantId, date, duration } = req.query;
    if (!merchantId || !date || !duration) {
      res.status(400).json({ success: false, message: 'Missing parameters: merchantId, date, and duration are required.' });
      return;
    }

    // Define business operational hour steps (e.g., 09:00 to 17:00 at 30 min intervals)
    const standardSlots = [
      '09:00', '09:30', '10:00', '10:30', '11:00', '11:30', '12:00', 
      '12:30', '13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30'
    ];

    const totalStaff = await prisma.employee.count({ 
      where: { 
        merchantId: String(merchantId),
        isActive: true // 🔥 Filters to only count active staff
      } 
    });
    const durationMs = Number(duration) * 60000;
    const availableSlots: string[] = [];

    for (const slot of standardSlots) {
      const slotStartTime = new Date(`${date}T${slot}:00`);
      const slotEndTime = new Date(slotStartTime.getTime() + durationMs);

      const activeBookings = await prisma.appointment.count({
        where: {
          merchantId: String(merchantId),
          status: { in: [AppointmentStatus.PENDING, AppointmentStatus.PAID, AppointmentStatus.COMPLETED] },
          OR: [
            { startTime: { lte: slotStartTime }, endTime: { gt: slotStartTime } },
            { startTime: { lt: slotEndTime }, endTime: { gte: slotEndTime } }
          ]
        }
      });

      // Show the time option only if booking load hasn't hit total staff headcount
      if (activeBookings < totalStaff) {
        availableSlots.push(slot);
      }
    }

    res.status(200).json({ success: true, data: availableSlots });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Error parsing slot visibility values.' });
  }
};