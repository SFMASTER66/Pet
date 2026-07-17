import { Gender, PetStatus, AppointmentStatus, UserRole } from '@prisma/client';
import prisma from './db';

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
}

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
        // ===================================================================
        // 🔥 FIX: Check both phone and email to avoid unique constraint violations
        // ===================================================================
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
        // ===================================================================

        // 2. Resolve or dynamically bundle target pet profile records under the master layout customer profile
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

        // 4. Calculate isolated snapshot scheduling durations
        const parsedStartTime = new Date(input.serviceTime);
        const calculatedEndTime = new Date(parsedStartTime.getTime() + (matrixRow.durationMinutes * 60000));

        // 5. STAFF CAPACITY GUARD
        const totalStaffCount = await prisma.employee.count({
          where: { 
            merchantId: input.merchantId, 
            isActive: true,
            user: {
              role: UserRole.MERCHANT_STAFF 
            }
          }
        });

        const concurrentBookings = await prisma.appointment.count({
          where: {
            merchantId: input.merchantId,
            status: { in: [AppointmentStatus.PENDING, AppointmentStatus.PAID, AppointmentStatus.COMPLETED] },
            OR: [
              {
                startTime: { lte: parsedStartTime },
                endTime: { gt: parsedStartTime }
              },
              {
                startTime: { lt: calculatedEndTime },
                endTime: { gte: calculatedEndTime }
              }
            ]
          }
        });

        if (concurrentBookings >= totalStaffCount) {
          throw new Error(`❌ Slot fully booked. Capacity reached for the selected time window.`);
        }

        // 6. Atomic transaction write directly to database cluster rows
        const appointment = await prisma.appointment.create({
          data: {
            pet: { connect: { id: petProfile.id } },
            merchant: { connect: { id: input.merchantId } },
            bookedBy: { connect: { id: input.bookedById } },
            servicePricingMatrix: { connect: { id: matrixRow.id } },
            groomer: input.groomerId 
              ? { connect: { id: input.groomerId } } 
              : undefined, 
            startTime: parsedStartTime,
            endTime: calculatedEndTime,
            status: AppointmentStatus.PENDING,
            priceCentsAud: matrixRow.priceCentsAud, 
            durationMinutes: matrixRow.durationMinutes, 
            notes: input.note ?? null
          },
          include: {
            pet: true,
            servicePricingMatrix: true
          }
        });

        return {
          success: true,
          message: 'Administrative booking saved and snapshot values written successfully.',
          data: appointment
        };
      }
      catch (error: any) {
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

      const updateData: any = { ...input };

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
          const totalStaffCount = await prisma.employee.count({
            where: { 
              merchantId: existingAppointment.merchantId, 
              isActive: true,
              user: {
                role: UserRole.MERCHANT_STAFF 
              }
             }
          });

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

  async getAvailableSlots(merchantId: string, dateStr: string, duration: number): Promise<string[]> {
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

    // 2. CAPACITY & BOUNDARY SYSTEM SETUP
    const totalStaff = await prisma.employee.count({
          where: { 
            merchantId: merchantId, 
            isActive: true,
            user: {
              role: UserRole.MERCHANT_STAFF 
            }
          }
        });

    if (totalStaff === 0) {
      return [];
    }

    const businessStart = new Date(`${dateStr}T${todayHours.openTime}:00`);
    const businessEnd = new Date(`${dateStr}T${todayHours.closeTime}:00`);
    const durationMs = duration * 60000;
    
    // 🔥 FIXED CHANGELOG: Shifted step from 30 minutes to 60 minutes (1-hour gap)
    const stepMs = 60 * 60000; 

    // 3. BULK FETCH BOOKINGS FOR PERFORMANCE
    const activeBookings = await prisma.appointment.findMany({
      where: {
        merchantId,
        status: { in: [AppointmentStatus.PENDING, AppointmentStatus.PAID, AppointmentStatus.COMPLETED] },
        startTime: { lt: businessEnd },
        endTime: { gt: businessStart }
      }
    });

    const availableSlots: string[] = [];
    let currentSlotStart = new Date(businessStart.getTime());

    // 4. TIMELINE CONCURRENCY ENGINE (Checks 9, 10, 11... until 4)
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

        let concurrentLoad = 0;
        for (const appt of overlappingBookings) {
          const apptStartMs = new Date(appt.startTime).getTime();
          const apptEndMs = new Date(appt.endTime).getTime();
          if (apptStartMs <= midpoint && apptEndMs >= midpoint) {
            concurrentLoad++;
          }
        }

        // If load reaches or exceeds staff limits at any point in the hour, block it
        if (concurrentLoad >= totalStaff) {
          isSlotAvailable = false;
          break;
        }
      }

      if (isSlotAvailable) {
        const hoursStr = String(slotStartTime.getHours()).padStart(2, '0');
        const minsStr = String(slotStartTime.getMinutes()).padStart(2, '0');
        availableSlots.push(`${hoursStr}:${minsStr}`);
      }

      // Step forward by exactly 1 hour
      currentSlotStart = new Date(currentSlotStart.getTime() + stepMs);
    }

    return availableSlots;
  }
};