import { Gender, PetStatus, AppointmentStatus, UserRole } from '@prisma/client';
import prisma from './db';
import nodemailer from 'nodemailer';
import { 
  getOwnerBookingEmailOptions, 
  getCustomerBookingEmailOptions, 
  BookingEmailData 
} from '../email-templates/booking-email';

// Strict Type Definitions for Operational Validation Inputs
interface CreatePetInput {
  ownerId: string;
  speciesId: number;
  breed: string;
  name: string;
  microchipNumber?: string;
  gender: Gender;
  isDesexed: boolean;
  dob?: string | Date; 
  behaviorTags?: string[];
  behaviorNotes?: string;
  merchantId: string;
}

interface AdminCreateBookingInput {
  merchantId: string;
  bookedById: string;
  servicePricingMatrixId: number;
  dogName: string;
  dogBreed: string;
  dogGender: Gender;
  isDesexed: boolean;
  dogWeight: number;
  dogDob: Date;
  ownerName: string;
  ownerPhone: string;
  ownerEmail: string;
  serviceTime: string;
  groomerId: string;
  note?: string;
}

interface AdminUpdateBookingInput {
  status?: AppointmentStatus;
  startTime?: string;
  isCheckedIn?: boolean;
  depositPaid?: boolean;
  isReadyToPickup?: boolean;
  isLoyaltyWaived?: boolean;
  internalTags?: string[];
  paymentIntentId?: string;
  groomerId?: string;
}

interface AddOnInput {
  addOnId: string;
  quantity: number;
  unitPriceCents: number;
}

interface AdminCreateBookingInput {
  merchantId: string;
  bookedById: string;
  servicePricingMatrixId: number;
  dogName: string;
  dogBreed: string;
  dogGender: Gender;
  isDesexed: boolean;
  dogWeight: number;
  dogDob: Date;
  ownerName: string;
  ownerPhone: string;
  ownerEmail: string;
  serviceTime: string;
  groomerId: string;
  note?: string;
  addOns?: AddOnInput[]; // 👈 Add addOns interface property
}

// Reusable transporter generation utility
const createTransporter = () => {
  const host = process.env.SMTP_HOST || 'smtp.resend.com';
  const port = Number(process.env.SMTP_PORT) || 465;

  return nodemailer.createTransport({
    host: host,
    port: port,
    secure: port === 465, // true for port 465, false for 587
    auth: {
      user: process.env.SMTP_USER || 'resend', // For Resend, username is literally 'resend'
      pass: process.env.SMTP_PASS,            // Your API key (re_123456789...)
    },
    // Cloud host timeout safeguards
    connectionTimeout: 10000,
    greetingTimeout: 10000,
    socketTimeout: 10000,
  });
};

export const BookingService = {
  /**
   * 🔍 Fetches all pricing matrix profiles for drop-down configuration layers
   */
  async getAvailableServices(merchantId: string) {
    return await prisma.servicePricingMatrix.findMany({
      where: { merchantId },
      orderBy: { name: 'asc' }
    });
  },

  /**
   * 🏗️ Original public customer facing workflow handler
   */
  async createAppointment(input: CreatePetInput) {
      const {
        ownerId,
        speciesId,
        breed,
        name,
        microchipNumber,
        gender,
        isDesexed,
        dob,
        behaviorTags = [],
        behaviorNotes,
        merchantId,
      } = input;

      // 🔒 Business Safety Verification Guard
      if (microchipNumber) {
        const existingPet = await prisma.pet.findUnique({
          where: { microchipNumber: microchipNumber.trim() },
        });
        if (existingPet) {
          throw new Error(`❌ Microchip number [${microchipNumber}] is already registered to another pet profile.`);
        }
      }

      const ownerExists = await prisma.user.findUnique({
        where: { id: ownerId },
        include: {
          employee: true, // 👈 This fetches the related employee data along with the user
        },
      });
      if (!ownerExists) {
        throw new Error(`❌ Target owner record ID [${ownerId}] cannot be located.`);
      }

      const parsedDob = dob ? new Date(dob) : null;

      const newPet = await prisma.pet.create({
        data: {
          ownerId,
          speciesId,
          breed: breed.trim(),
          name: name.trim(),
          microchipNumber: microchipNumber ? microchipNumber.trim() : null,
          status: PetStatus.ACTIVE,
          gender,
          isDesexed,
          dob: parsedDob,
          behaviorTags,
          behaviorNotes,
          merchantId,
        },
        include: {
          species: true,
          owner: {
            select: { name: true, email: true, phoneNumber: true },
          },
        },
      });

      let ageText = 'Unknown Age';
      if (parsedDob) {
        const now = new Date();
        let years = now.getFullYear() - parsedDob.getFullYear();
        let months = now.getMonth() - parsedDob.getMonth();
        if (months < 0) {
          years--;
          months += 12;
        }
        ageText = `${years} yrs ${months} mos`;
      }

      return {
        success: true,
        message: 'Pet registered successfully for tracking parameters.',
        pet: {
          id: newPet.id,
          name: newPet.name,
          breed: newPet.breed,
          ageText,
          ownerName: newPet.owner.name
        }
      };
    },

    /**
     * 🚀 Dynamic Administrative Manual Booking Engine Core
     */
   async portalBooking(input: AdminCreateBookingInput) {
  try { 
    // 1. Resolve customer profile record details safely by phone OR email
    let userProfile = await prisma.user.findFirst({
      where: { 
        merchantId: input.merchantId,
        OR: [
          { phoneNumber: input.ownerPhone.trim() },
          { email: input.ownerEmail.trim().toLowerCase() }
        ]
      }
    });

    if (!userProfile) {
      userProfile = await prisma.user.create({
        data: {
          merchantId: input.merchantId,
          name: input.ownerName.trim(),
          email: input.ownerEmail.trim().toLowerCase(),
          phoneNumber: input.ownerPhone.trim(),
          passwordHash: '$2b$10$UnusableFallbackHashValuePlaceholderEngineToken', 
          role: 'CUSTOMER'
        }
      });
    }

    // 2. Resolve or dynamically bundle target pet profile records
    let petProfile = await prisma.pet.findFirst({
      where: {
        merchantId: input.merchantId,
        ownerId: userProfile.id,
        name: { equals: input.dogName.trim(), mode: 'insensitive' }
      }
    });

    if (!petProfile) {
      const defaultSpecies = await prisma.species.findFirst({ where: { name: 'Dog' } });
      if (!defaultSpecies) {
        throw new Error("System fault: Master core database record configurations for 'Dog' options are missing.");
      }

      petProfile = await prisma.pet.create({
        data: {
          merchantId: input.merchantId,
          ownerId: userProfile.id,
          speciesId: defaultSpecies.id,
          name: input.dogName.trim(),
          breed: input.dogBreed.trim(),
          dob: input.dogDob,
          weight: input.dogWeight,
          gender: input.dogGender,
          isDesexed: input.isDesexed,
          status: 'ACTIVE'
        }
      });
    }

    // 3. Resolve master base duration matrix parameters
    const matrixRow = await prisma.servicePricingMatrix.findUnique({
      where: { id: input.servicePricingMatrixId }
    });

    if (!matrixRow) {
      throw new Error(`❌ Pricing matrix target key row configuration [${input.servicePricingMatrixId}] was not found.`);
    }

    // 4. Calculate snapshot scheduling durations
    const parsedStartTime = new Date(input.serviceTime);
    const calculatedEndTime = new Date(parsedStartTime.getTime() + (matrixRow.durationMinutes * 60000));

    const startOfDay = new Date(parsedStartTime);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(parsedStartTime);
    endOfDay.setHours(23, 59, 59, 999);

    const shiftsOnDay = await prisma.shift.findMany({
      where: {
        date: { gte: startOfDay, lte: endOfDay },
        employee: {
          merchantId: input.merchantId,
          isActive: true,
          user: { role: UserRole.MERCHANT_STAFF }
        }
      },
      select: { employeeId: true }
    });

    // 5. Build eligible active staff pool
    let eligibleStaffIds: string[] = [];
    if (shiftsOnDay.length > 0) {
      eligibleStaffIds = Array.from(new Set(shiftsOnDay.map((s) => s.employeeId)));
    } else {
      const fallbackStaff = await prisma.employee.findMany({
        where: { 
          merchantId: input.merchantId, 
          isActive: true,
          user: { role: UserRole.MERCHANT_STAFF }
        },
        select: { id: true }
      });
      eligibleStaffIds = fallbackStaff.map((s) => s.id);
    }

    const totalStaffCount = eligibleStaffIds.length;

    // ===================================================================
    // ⏱️ 30-MINUTE TIMEOUT & SAME-USER RE-BOOKING LOGIC
    // ===================================================================
    const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000);

    // Fetch overlapping bookings (including DEPOSIT_NOT_PAID)
    const overlappingBookings = await prisma.appointment.findMany({
      where: {
        merchantId: input.merchantId,
        status: { 
          in: [
            AppointmentStatus.PENDING, 
            AppointmentStatus.DEPOSIT_NOT_PAID, 
            AppointmentStatus.PAID, 
            AppointmentStatus.COMPLETED
          ] 
        },
        OR: [
          { startTime: { lte: parsedStartTime }, endTime: { gt: parsedStartTime } },
          { startTime: { lt: calculatedEndTime }, endTime: { gte: calculatedEndTime } }
        ]
      },
      select: {
        id: true,
        groomerId: true,
        status: true,
        createdAt: true,
        bookedById: true,
        depositPaid: true
      }
    });

    // Helper flag for unpaid statuses
    const isUnpaidStatus = (status: AppointmentStatus) => 
      status === AppointmentStatus.PENDING || status === AppointmentStatus.DEPOSIT_NOT_PAID;

    // Check if the exact same user has an active unpaid reservation for this timeframe
    const existingUserPendingBooking = overlappingBookings.find(
      (b) => b.bookedById === userProfile.id && isUnpaidStatus(b.status)
    );

    // Filter out active, valid conflicting bookings
    const validConflictingBookings = overlappingBookings.filter((b) => {
      // Ignore the user's own existing draft (we will update it instead)
      if (b.bookedById === userProfile.id && isUnpaidStatus(b.status)) {
        return false;
      }
      // Unpaid bookings older than 30 mins are treated as released
      if (
        isUnpaidStatus(b.status) &&
        b.createdAt &&
        new Date(b.createdAt).getTime() < thirtyMinutesAgo.getTime()
      ) {
        return false;
      }
      return true;
    });

    // Capacity Check
    const isAdminBooking = Boolean(input.bookedById && input.bookedById.trim() !== "");
    if (!isAdminBooking) {
      if (validConflictingBookings.length >= totalStaffCount) {
        throw new Error(`❌ Slot fully booked. Capacity reached for the selected time window.`);
      }
    }

    // Groomer Auto-Assignment
    let assignedGroomerId = input.groomerId || undefined;

    if (!assignedGroomerId) {
      // 1. Gather ALL staff members who currently have an active overlapping booking
      const occupiedGroomerIds = new Set(
        overlappingBookings
          .filter((b) => {
            // If deposit is NOT paid, check if the booking has expired (>30 mins old)
            if (!b.depositPaid) {
              const isExpired =
                b.createdAt &&
                new Date(b.createdAt).getTime() < thirtyMinutesAgo.getTime();
                
              // Keep active temporary locks (created within last 30 mins)
              // Ignore expired locks (older than 30 mins)
              return !isExpired;
            }

            // Deposit is paid: treat groomer as definitely occupied
            return true;
          })
          .map((b) => b.groomerId)
          .filter((id): id is string => Boolean(id))
      );

      // 2. Find a staff member from eligibleStaffIds who has ZERO active bookings in this slot
      const strictlyAvailableStaffId = eligibleStaffIds.find(
        (staffId) => !occupiedGroomerIds.has(staffId)
      );

      // 3. Assign the completely free staff member
      assignedGroomerId = strictlyAvailableStaffId;
    }

    // ===================================================================
    // 6. Write or Update Database Record
    // ===================================================================
    const formattedAddOns = (input.addOns || []).map((addon) => ({
      addOnId: addon.addOnId,
      quantity: addon.quantity,
      unitPriceCents: addon.unitPriceCents,
      totalPriceCents: addon.quantity * addon.unitPriceCents,
    }));

    let appointment;

    if (existingUserPendingBooking) {
      // 🔄 SAME USER RE-BOOKING / REFRESH: Update existing draft appointment
      appointment = await prisma.appointment.update({
        where: { id: existingUserPendingBooking.id },
        data: {
          petId: petProfile.id,
          servicePricingMatrixId: matrixRow.id,
          groomerId: assignedGroomerId ?? null,
          startTime: parsedStartTime,
          endTime: calculatedEndTime,
          status: isAdminBooking ? AppointmentStatus.PENDING : AppointmentStatus.DEPOSIT_NOT_PAID,
          priceCentsAud: matrixRow.priceCentsAud,
          durationMinutes: matrixRow.durationMinutes,
          notes: input.note ?? null,
          // 🟢 Delete old add-ons and recreate fresh ones for updated appointment
          addOns: {
            deleteMany: {},
            createMany: {
              data: formattedAddOns,
            },
          },
        },
        include: {
          pet: true,
          servicePricingMatrix: true,
          addOns: {
            include: { addOn: true },
          },
        },
      });
    } else {
      // 🆕 NEW BOOKING: Create fresh appointment row
      appointment = await prisma.appointment.create({
        data: {
          pet: { connect: { id: petProfile.id } },
          merchant: { connect: { id: input.merchantId } },
          bookedBy: {
            connect: { id: isAdminBooking ? input.bookedById! : userProfile.id },
          },
          servicePricingMatrix: { connect: { id: matrixRow.id } },
          groomer: assignedGroomerId ? { connect: { id: assignedGroomerId } } : undefined,
          startTime: parsedStartTime,
          endTime: calculatedEndTime,
          status: isAdminBooking ? AppointmentStatus.PENDING : AppointmentStatus.DEPOSIT_NOT_PAID,
          priceCentsAud: matrixRow.priceCentsAud,
          durationMinutes: matrixRow.durationMinutes,
          notes: input.note ?? null,
          // 🟢 Create nested add-ons records during creation
          addOns: {
            createMany: {
              data: formattedAddOns,
            },
          },
        },
        include: {
          pet: true,
          servicePricingMatrix: true,
          addOns: {
            include: { addOn: true },
          },
        },
      });
    }

    return {
      success: true,
      message: existingUserPendingBooking
        ? 'Pending reservation updated successfully.'
        : 'Administrative booking saved and snapshot values written successfully.',
      data: appointment
    };
  } catch (error: any) {
    throw new Error(error.message);
  }
},

  /**
   * 🔄 Modifies an existing booking state matrix parameter layout row
   */
  async updateBooking(id: string, input: AdminUpdateBookingInput) {
    try {
      const existingAppointment = await prisma.appointment.findUnique({ where: { id } });
      if (!existingAppointment) throw new Error(`❌ Appointment [${id}] not found.`);

      // 1. Separate groomerId out from the rest of the inputs
      const { groomerId, ...restOfInput } = input;
      const updateData: any = { ...restOfInput };

      // ==========================================
      // 🔥 CAPACITY GUARD RUNS ONLY ON TIME CHANGE
      // ==========================================
      if (input.startTime) {
        const parsedStartTime = new Date(input.startTime);
        
        // Only run capacity validation if the start time is actually changing
        const isTimeChanging = existingAppointment.startTime.getTime() !== parsedStartTime.getTime();

        const duration = existingAppointment.durationMinutes || 60; 
        const calculatedEndTime = new Date(parsedStartTime.getTime() + duration * 60000);

        if (isTimeChanging) {
          // ///////////////////////////////////////////////////////////////////////////
          // 🟢 HIGHLIGHTED CHANGE: Check Shift records for capacity on update
          // ///////////////////////////////////////////////////////////////////////////
          const startOfDay = new Date(parsedStartTime);
          startOfDay.setHours(0, 0, 0, 0);

          const endOfDay = new Date(parsedStartTime);
          endOfDay.setHours(23, 59, 59, 999);

          const shiftsOnDay = await prisma.shift.findMany({
            where: {
              date: {
                gte: startOfDay,
                lte: endOfDay
              },
              employee: {
                merchantId: existingAppointment.merchantId,
                isActive: true,
                user: {
                  role: UserRole.MERCHANT_STAFF
                }
              }
            },
            select: { employeeId: true }
          });

          let totalStaffCount = 0;

          if (shiftsOnDay.length > 0) {
            const uniqueEmployeeIds = new Set(shiftsOnDay.map((s) => s.employeeId));
            totalStaffCount = uniqueEmployeeIds.size;
          } else {
            totalStaffCount = await prisma.employee.count({
              where: { 
                merchantId: existingAppointment.merchantId, 
                isActive: true,
                user: {
                  role: UserRole.MERCHANT_STAFF 
                }
              }
            });
          }
          // ///////////////////////////////////////////////////////////////////////////

          const concurrentBookings = await prisma.appointment.count({
            where: {
              id: { not: id },
              merchantId: existingAppointment.merchantId,
              status: { in: [AppointmentStatus.PENDING, AppointmentStatus.PAID, AppointmentStatus.COMPLETED] },
              OR: [
                { startTime: { lte: parsedStartTime }, endTime: { gt: parsedStartTime } },
                { startTime: { lt: calculatedEndTime }, endTime: { gte: calculatedEndTime } }
              ]
            }
          });

          if (concurrentBookings >= totalStaffCount) {
            throw new Error(`❌ Rescheduling rejected. No staff capacity during this period.`);
          }
        }

        updateData.startTime = parsedStartTime;
        updateData.endTime = calculatedEndTime;
      }
      // ==========================================

      // 2. Safely evaluate groomerId relation strategy before executing update
      if (groomerId !== undefined) {
        const hasGroomer = groomerId !== null && groomerId !== '';
        
        updateData.groomer = hasGroomer 
          ? { connect: { id: groomerId } } 
          : { disconnect: true }; // Breaks relation if empty string/null passed from front-end
      }

      const updatedAppointment = await prisma.appointment.update({
        where: { id },
        data: updateData,
        include: { pet: true, servicePricingMatrix: true },
      });

      return { success: true, data: updatedAppointment };
    } catch (error: any) {
      throw new Error(error.message);
    }
  },

  async deleteBooking(id: string) {
    try {
      const existingAppointment = await prisma.appointment.findUnique({
        where: { id },
      });

      if (!existingAppointment) {
        throw new Error(`❌ Appointment with unique context identifier [${id}] was not found.`);
      }

      await prisma.appointment.delete({
        where: { id },
      });

      return {
        success: true,
        message: 'Administrative appointment removed successfully from persistent storage.',
      };
    } catch (error: any) {
      throw new Error(error.message);
    }
  },

  async getAvailableSlots(
    merchantId: string, 
    dateStr: string, 
    duration: number,
    userId?: string
  ): Promise<string[]> {
      const targetDate = new Date(`${dateStr}T00:00:00`);
      if (isNaN(targetDate.getTime())) {
        throw new Error('Invalid date format provided.');
      }

      // 1. DYNAMIC BUSINESS HOURS FETCHING & SEEDING LOGIC
      let businessHours = await prisma.businessHours.findMany({
        where: { merchantId },
        orderBy: { dayOfWeek: 'asc' },
      });

      if (businessHours.length === 0) {
        const defaults = Array.from({ length: 7 }, (_, i) => ({
          merchantId,
          dayOfWeek: i + 1,
          openTime: '09:00',
          closeTime: '17:00',
          isClosed: (i + 1) > 5, // Sat & Sun closed by default
        }));

        await prisma.businessHours.createMany({ data: defaults });
        
        businessHours = await prisma.businessHours.findMany({
          where: { merchantId },
          orderBy: { dayOfWeek: 'asc' },
        });
      }

      const currentDayOfWeek = targetDate.getDay() === 0 ? 7 : targetDate.getDay();
      const todayHours = businessHours.find(bh => bh.dayOfWeek === currentDayOfWeek);

      if (!todayHours || todayHours.isClosed) {
        return [];
      }

      // 2. Read Shift records to find active capacity for slot lookup
      const startOfDay = new Date(`${dateStr}T00:00:00.000Z`);
      const endOfDay = new Date(`${dateStr}T23:59:59.999Z`);

      const shiftsOnDay = await prisma.shift.findMany({
        where: {
          date: {
            gte: startOfDay,
            lte: endOfDay
          },
          employee: {
            merchantId: merchantId,
            isActive: true,
            user: {
              role: UserRole.MERCHANT_STAFF
            }
          }
        },
        select: { employeeId: true }
      });

      let totalStaff = 0;

      if (shiftsOnDay.length > 0) {
        const uniqueEmployeeIds = new Set(shiftsOnDay.map((s) => s.employeeId));
        totalStaff = uniqueEmployeeIds.size;
      } else {
        totalStaff = await prisma.employee.count({
          where: { 
            merchantId: merchantId, 
            isActive: true,
            user: {
              role: UserRole.MERCHANT_STAFF 
            }
          }
        });
      }

      if (totalStaff === 0) {
        return [];
      }

      const businessStart = new Date(`${dateStr}T${todayHours.openTime}:00`);
      const businessEnd = new Date(`${dateStr}T${todayHours.closeTime}:00`);
      const durationMs = duration * 60000;
      const stepMs = 60 * 60000; // Step forward by 1 hour

      // 3. BULK FETCH BOOKINGS WITH 30-MIN TIMEOUT LOGIC
      const fetchedBookings = await prisma.appointment.findMany({
        where: {
          merchantId,
          status: { 
            in: [
              AppointmentStatus.PENDING, 
              AppointmentStatus.DEPOSIT_NOT_PAID,
              AppointmentStatus.PAID, 
              AppointmentStatus.COMPLETED
            ] 
          },
          startTime: { lt: businessEnd },
          endTime: { gt: businessStart }
        },
        select: {
          id: true,
          startTime: true,
          endTime: true,
          groomerId: true,
          status: true,
          depositPaid: true, // 👈 Added depositPaid check
          createdAt: true,
          bookedById: true,
          bookedBy: {
            select: {
              role: true
            }
          }
        }
      });

      // ===================================================================
      // ⏱️ 30-MINUTE TIMEOUT & SAME-USER RE-BOOKING FILTER
      // ===================================================================
      const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000);

      const activeBookings = fetchedBookings.filter(appt => {
        // An appointment is treated as an unpaid draft only if depositPaid is false 
        // AND status is PENDING or DEPOSIT_NOT_PAID
        const isUnpaidStatus = 
          !appt.depositPaid;

        // 1. If it's an unpaid draft created by staff, ignore it (keep slot available)
        if (isUnpaidStatus && appt.bookedBy?.role === UserRole.MERCHANT_STAFF) {
          return false;
        }

        // 2. Ignore current user's unpaid draft so they aren't blocked by their own pending reservation
        if (userId && appt.bookedById === userId && isUnpaidStatus) {
          return false;
        }

        // 3. Ignore customer unpaid appointments created over 30 mins ago
        if (
          isUnpaidStatus &&
          appt.createdAt &&
          new Date(appt.createdAt).getTime() < thirtyMinutesAgo.getTime()
        ) {
          return false;
        }

        return true;
      });

      const availableSlots: string[] = [];
      let currentSlotStart = new Date(businessStart.getTime());

      // 4. TIMELINE CONCURRENCY ENGINE
      while (currentSlotStart.getTime() + durationMs <= businessEnd.getTime()) {
        const slotStartTime = new Date(currentSlotStart.getTime());
        const slotEndTime = new Date(currentSlotStart.getTime() + durationMs);

        // Filter appointments overlapping this specific hourly window
        const overlappingBookings = activeBookings.filter(appt => {
          const apptStart = new Date(appt.startTime);
          const apptEnd = new Date(appt.endTime);
          return apptStart < slotEndTime && apptEnd > slotStartTime;
        });

        // Break down the window into sub-intervals based on overlap transitions
        const timePointsSet = new Set<number>();
        timePointsSet.add(slotStartTime.getTime());
        timePointsSet.add(slotEndTime.getTime());

        for (const appt of overlappingBookings) {
          const apptStartMs = new Date(appt.startTime).getTime();
          const apptEndMs = new Date(appt.endTime).getTime();
          
          if (apptStartMs > slotStartTime.getTime() && apptStartMs < slotEndTime.getTime()) {
            timePointsSet.add(apptStartMs);
          }
          if (apptEndMs > slotStartTime.getTime() && apptEndMs < slotEndTime.getTime()) {
            timePointsSet.add(apptEndMs);
          }
        }

        const sortedTimePoints = Array.from(timePointsSet).sort((a, b) => a - b);
        let isSlotAvailable = true;

        // Validate capacity inside every sub-interval segment
        for (let i = 0; i < sortedTimePoints.length - 1; i++) {
          const t1 = sortedTimePoints[i];
          const t2 = sortedTimePoints[i + 1];
          const midpoint = (t1 + t2) / 2;

          const busyStaffSet = new Set<string>();
          let unassignedBookingsCount = 0;

          for (const appt of overlappingBookings) {
            const apptStartMs = new Date(appt.startTime).getTime();
            const apptEndMs = new Date(appt.endTime).getTime();
            if (apptStartMs <= midpoint && apptEndMs >= midpoint) {
              if (appt.groomerId) {
                busyStaffSet.add(appt.groomerId);
              } else {
                unassignedBookingsCount++;
              }
            }
          }

          const occupiedStaffCapacity = busyStaffSet.size + unassignedBookingsCount;

          if (occupiedStaffCapacity >= totalStaff) {
            isSlotAvailable = false;
            break;
          }
        }

        if (isSlotAvailable) {
          const hoursStr = String(slotStartTime.getHours()).padStart(2, '0');
          const minsStr = String(slotStartTime.getMinutes()).padStart(2, '0');
          availableSlots.push(`${hoursStr}:${minsStr}`);
        }

        currentSlotStart = new Date(currentSlotStart.getTime() + stepMs);
      }

      return availableSlots;
    },

  async getAdminBusinessSlots(merchantId: string, dateStr: string): Promise<string[]> {
    const targetDate = new Date(`${dateStr}T00:00:00`);
    if (isNaN(targetDate.getTime())) {
      throw new Error('Invalid date format provided.');
    }

    // 1. DYNAMIC BUSINESS HOURS FETCHING & SEEDING LOGIC
    let businessHours = await prisma.businessHours.findMany({
      where: { merchantId },
      orderBy: { dayOfWeek: 'asc' },
    });

    if (businessHours.length === 0) {
      const defaults = Array.from({ length: 7 }, (_, i) => ({
        merchantId,
        dayOfWeek: i + 1,
        openTime: '09:00',
        closeTime: '17:00',
        isClosed: (i + 1) > 5, // Sat & Sun closed by default
      }));

      await prisma.businessHours.createMany({ data: defaults });
      
      businessHours = await prisma.businessHours.findMany({
        where: { merchantId },
        orderBy: { dayOfWeek: 'asc' },
      });
    }

    // Map JS Sunday (0) to DB format (7)
    const currentDayOfWeek = targetDate.getDay() === 0 ? 7 : targetDate.getDay();
    const todayHours = businessHours.find(bh => bh.dayOfWeek === currentDayOfWeek);

    // If the day is explicitly marked as closed, return no slots
    if (!todayHours || todayHours.isClosed) {
      return [];
    }

    // 2. PARSE STRINGS INTO DATE OBJECTS FOR TIME CALCULATIONS
    const businessStart = new Date(`${dateStr}T${todayHours.openTime}:00`);
    const businessEnd = new Date(`${dateStr}T${todayHours.closeTime}:00`);
    
    // Exactly 1-hour step conversions
    const stepMs = 60 * 60000; 

    const adminSlots: string[] = [];
    let currentSlotStart = new Date(businessStart.getTime());

    // 3. TIMELINE SEGMENTATION ENGINE
    while (currentSlotStart.getTime() + stepMs <= businessEnd.getTime()) {
      // 🟢 UPDATED: Output 24-hour format with 2-digit padding matching getAvailableSlots
      const hoursStr = String(currentSlotStart.getHours()).padStart(2, '0');
      const minsStr = String(currentSlotStart.getMinutes()).padStart(2, '0');

      adminSlots.push(`${hoursStr}:${minsStr}`);

      // Step forward by exactly 1 hour
      currentSlotStart = new Date(currentSlotStart.getTime() + stepMs);
    }

    return adminSlots;
  },

  async deleteAppointmentAddOn(appointmentAddOnId: string) {
    return await prisma.appointmentAddOn.delete({
      where: { id: appointmentAddOnId },
    });
  },
  
  async sendBookingConfirmationEmails(data: BookingEmailData) {
    try {
      const transporter = createTransporter();

      const ownerMailOptions = getOwnerBookingEmailOptions(data);
      const customerMailOptions = getCustomerBookingEmailOptions(data);

      // Send both emails concurrently
      await Promise.all([
        transporter.sendMail(ownerMailOptions),
        transporter.sendMail(customerMailOptions),
      ]);

      return {
        success: true,
        message: 'Booking notification emails successfully sent to owner and customer.',
      };
    } catch (error: any) {
      console.error('❌ Error sending booking confirmation emails:', error);
      
      return {
        success: false,
        message: error.message || 'Failed to dispatch booking notification emails.',
      };
    }
  }
};