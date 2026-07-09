import { Gender, PetStatus, AppointmentStatus } from '@prisma/client';
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
      // 1. Resolve or dynamically upscale customer profile record details
      let userProfile = await prisma.user.findFirst({
        where: { 
          merchantId: input.merchantId,
          phoneNumber: input.ownerPhone.trim()
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

      // 5. Atomic transaction write directly to database cluster rows
      const appointment = await prisma.appointment.create({
        data: {
          // 1. Required Relations mapped uniformly via connect objects
          pet: {
            connect: { id: petProfile.id }
          },
          merchant: {
            connect: { id: input.merchantId }
          },
          bookedBy: {
            connect: { id: input.bookedById }
          },
          servicePricingMatrix: {
            connect: { id: matrixRow.id }
          },

          // 2. Optional relation handled dynamically via connect or undefined
          groomer: input.groomerId 
            ? { connect: { id: input.groomerId } } 
            : undefined, 

          // 3. Native Model Columns & Isolated Data Snapshots
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
      const existingAppointment = await prisma.appointment.findUnique({
        where: { id },
      });

      if (!existingAppointment) {
        throw new Error(`❌ Appointment with unique context identifier [${id}] was not found.`);
      }

      const updateData: any = {
        status: input.status,
        isCheckedIn: input.isCheckedIn,
        depositPaid: input.depositPaid,
        isReadyToPickup: input.isReadyToPickup,
        isLoyaltyWaived: input.isLoyaltyWaived,
        internalTags: input.internalTags,
      };

      // Recalculate end times dynamically if the start date tracker shifts layout windows
      if (input.startTime) {
        const parsedStartTime = new Date(input.startTime);
        const duration = existingAppointment.durationMinutes || 60; 
        updateData.startTime = parsedStartTime;
        updateData.endTime = new Date(parsedStartTime.getTime() + duration * 60000);
        updateData.durationMinutes = duration;
      }

      const updatedAppointment = await prisma.appointment.update({
        where: { id },
        data: updateData,
        include: {
          pet: true,
          servicePricingMatrix: true,
        },
      });

      return {
        success: true,
        message: 'Administrative appointment altered and snapshot metrics updated securely.',
        data: updatedAppointment,
      };
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
  }
};