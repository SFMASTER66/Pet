import prisma from './db';
import { UserRole, AppointmentStatus } from '@prisma/client';
import bcrypt from 'bcryptjs';

export interface DashboardSummary {
  totalRevenueAud: number;
  totalOrders: number;
  activeClients: number;
}

export interface FormattedAppointment {
  id: string;
  time: Date;
  endTime: Date;
  status: string;
  petName: string;
  breed: string | null;
  clientName: string;
  clientPhone: string;
  clientEmail: string;
  serviceName: string;
  price: number;
  isCheckedIn: boolean;
  depositPaid: boolean;
  isReadyToPickup: boolean;
  internalTags: string[];
}

export interface ClientContact {
  clientName: string;
  clientPhone: string;
  clientEmail: string;
}

export interface MerchantDashboardData {
  summary: DashboardSummary;
  recentAppointments: FormattedAppointment[];
  clients: ClientContact[];
}

export class MerchantService {
  // Method to fetch live service matrices from Prisma
  async getServiceMatrices(merchantId: string) {
    return await prisma.servicePricingMatrix.findMany({
      where: { merchantId },
      orderBy: { name: 'asc' }
    });
  }

  async getDashboardData(merchantId: string): Promise<MerchantDashboardData> {
    // 1. Fetch ALL appointments for the business across any status lifecycle step
    const appointments = await prisma.appointment.findMany({
      where: { merchantId }, 
      include: {
        servicePricingMatrix: true, 
        pet: { 
          include: { 
            owner: true 
          } 
        }
      },
      orderBy: { startTime: 'desc' }
    });

    let totalRevenueCents = 0; 
    const clientMap = new Map<string, ClientContact>();

    // 2. Map results cleanly to structured response layout formats
    const appointmentsList = appointments.map((app: any) => {
      const priceCents = app.priceCentsAud || 0;
      
      // Accumulate revenue calculation metrics safely
      totalRevenueCents += priceCents;

      if (app.pet?.owner) {
        clientMap.set(app.pet.owner.id, {
          clientName: app.pet.owner.name,
          clientPhone: app.pet.owner.phoneNumber || 'No Phone',
          clientEmail: app.pet.owner.email
        });
      }

      return {
        id: app.id,
        time: app.startTime,
        endTime: app.endTime,
        status: app.status,
        petName: app.pet?.name || 'Unknown Pet',
        breed: app.pet?.breed || 'Unknown Breed',
        clientName: app.pet?.owner?.name || 'Unknown Owner',
        clientPhone: app.pet?.owner?.phoneNumber || 'No Phone',
        clientEmail: app.pet?.owner?.email || '',
        serviceName: app.servicePricingMatrix?.name || 'Unknown Service',
        price: priceCents / 100,
        isCheckedIn: app.isCheckedIn ?? false,
        depositPaid: app.depositPaid ?? false,
        isReadyToPickup: app.isReadyToPickup ?? false,
        internalTags: app.internalTags || []
      };
    });

    return {
      summary: {
        totalRevenueAud: totalRevenueCents / 100, 
        totalOrders: appointments.length,
        activeClients: clientMap.size,
      },
      recentAppointments: appointmentsList,
      clients: Array.from(clientMap.values())
    };
  }

  // =========================================================================
  // 🔥 UPDATED METHOD SIGNATURE TO ACCEPT AN OPTIONAL 'search' VALUE
  // =========================================================================
  async getPaginatedCustomers(merchantId: string, page: number, limit: number, search?: string) {
    const skip = (page - 1) * limit;

    // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    // 🚀 CHANGE: WHERE CLAUSE BASE TARGETS USERS (OWNERS) WITH PETS AT THIS MERCHANT
    // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    const whereClause: any = {
      role: UserRole.CUSTOMER,
      pets: {
        some: {
          merchantId: merchantId,
        },
      },
    };

    if (search && search.length > 0) {
      whereClause.AND = [
        {
          OR: [
            { name: { contains: search, mode: 'insensitive' } },
            { email: { contains: search, mode: 'insensitive' } },
            { phoneNumber: { contains: search, mode: 'insensitive' } },
            {
              pets: {
                some: {
                  merchantId: merchantId,
                  OR: [
                    { name: { contains: search, mode: 'insensitive' } },
                    { breed: { contains: search, mode: 'insensitive' } },
                  ],
                },
              },
            },
          ],
        },
      ];
    }

    const [owners, totalCount] = await prisma.$transaction([
      prisma.user.findMany({
        where: whereClause,
        skip: skip,
        take: limit,
        include: {
          pets: {
            where: { merchantId: merchantId },
            include: {
              _count: {
                select: { appointments: true }
              },
              appointments: {
                where: {
                  status: {
                    in: [AppointmentStatus.PENDING, AppointmentStatus.PAID, AppointmentStatus.COMPLETED]
                  }
                },
                orderBy: { startTime: 'desc' },
                take: 1,
                include: {
                  servicePricingMatrix: true
                }
              }
            },
            orderBy: { name: 'asc' }
          }
        },
        orderBy: {
          name: 'asc',
        },
      }),
      prisma.user.count({
        where: whereClause,
      }),
    ]);

    const formattedRecords = owners.map((owner: any) => {
      return {
        id: owner.id,
        name: owner.name,
        email: owner.email || 'No contact email listed',
        phone: owner.phoneNumber || 'N/A',
        // MAP ALL PETS UNDER THIS SPECIFIC OWNER
        pets: owner.pets.map((pet: any) => {
          const lastAppointmentRaw = pet.appointments && pet.appointments.length > 0 ? pet.appointments[0] : null;
          
          const lastAppointment = lastAppointmentRaw ? {
            id: lastAppointmentRaw.id,
            startTime: lastAppointmentRaw.startTime,
            endTime: lastAppointmentRaw.endTime,
            status: lastAppointmentRaw.status,
            serviceName: lastAppointmentRaw.servicePricingMatrix?.name || 'Unknown Service',
          } : null;

          return {
            id: pet.id,
            name: pet.name,
            breed: pet.breed || 'N/A',
            gender: pet.gender || 'MALE',
            isDesexed: pet.isDesexed || false,
            notes: pet.behaviorNotes || null,
            appointmentCount: pet._count?.appointments ?? 0,
            lastAppointment: lastAppointment,
          };
        }),
      };
    });
    // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    const totalPages = Math.ceil(totalCount / limit) || 1;

    return {
      records: formattedRecords,
      totalPages: totalPages,
      totalCount: totalCount,
    };
  }
  
  async getMerchantStaff(merchantId: string) {
    return await prisma.user.findMany({
      where: {
        merchantId: merchantId,
        role: UserRole.MERCHANT_STAFF,
      },
      select: { 
      id: true, 
      name: true, 
      email: true, 
      role: true,
      // ========================================================
      // 🔥 FETCH THE ISACTIVE FIELD FROM THE EMPLOYEE RELATION
      // ========================================================
      employee: {
        select: {
          isActive: true
        }
      }
    },
    });
  }

  async addStaffAccount(data: {
    name: string;
    email: string;
    passwordRaw: string;
    merchantId: string;
  }) {
    const existingStaff = await prisma.user.findFirst({
      where: { email: data.email },
    });

    if (existingStaff) {
      throw new Error('An account with this email workspace record address identifier layout already exists.');
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(data.passwordRaw, salt);

    // Use a transaction to ensure both records are safely created together
    const staffUser = await prisma.$transaction(async (tx) => {
      // 1. Create the User record
      const user = await tx.user.create({
        data: {
          email: data.email,
          passwordHash: hashedPassword,
          name: data.name,
          role: UserRole.MERCHANT_STAFF,
          merchantId: data.merchantId,
        },
      });

      // 2. Create the Employee record using the newly generated User ID
      await tx.employee.create({
        data: {
          id: user.id, // Explicitly linking the IDs as requested
          merchantId: data.merchantId,
          name: data.name,
          isActive: true, // Explicitly ensuring they start as active
          // avatarUrl is optional, so it defaults to null
        },
      });

      return user;
    });

    return {
      id: staffUser.id,
      name: staffUser.name,
      email: staffUser.email,
      role: staffUser.role,
    };
  }

  async removeStaffAccount(staffId: string, merchantId: string, isActive: boolean) {
    return await prisma.$transaction(async (tx) => {
      // 1. Flip the Employee status to inactive
      await tx.employee.updateMany({
        where: {
          id: staffId,
          merchantId: merchantId,
        },
        data: {
          isActive: isActive,
        },
      });
    });
  }

  async getBusinessHours(merchantId: string) {
  // 1. Fetch current business hours records
  let hours = await prisma.businessHours.findMany({
    where: { merchantId },
    orderBy: { dayOfWeek: 'asc' },
  });

  // 2. If no entries exist yet, seed default standard business week records matching model constraints
  if (hours.length === 0) {
    const defaults = Array.from({ length: 7 }, (_, i) => ({
      merchantId,
      dayOfWeek: i + 1,
      openTime: '09:00',
      closeTime: '17:00',
      isClosed: (i + 1) > 5, // Saturday & Sunday closed by default
    }));

    await prisma.businessHours.createMany({ data: defaults });
    
    hours = await prisma.businessHours.findMany({
      where: { merchantId },
      orderBy: { dayOfWeek: 'asc' },
    });
  }

  return hours;
}

  async upsertBusinessHoursDay(
    merchantId: string, 
    dayOfWeek: number, 
    openTime: string, 
    closeTime: string, 
    isClosed: boolean
  ) {
    // Uses atomic unique composite key constraints: [merchantId, dayOfWeek]
    return await prisma.businessHours.upsert({
      where: {
        merchantId_dayOfWeek: {
          merchantId,
          dayOfWeek,
        },
      },
      update: {
        openTime,
        closeTime,
        isClosed,
      },
      create: {
        merchantId,
        dayOfWeek,
        openTime,
        closeTime,
        isClosed,
      },
    });
  }
  // =========================================================================
  // 🔥 INITIAL STATE GENERATION ENGINE: SEEDS ROSTER DATA DIRECTLY TO DB
  // =========================================================================
  async seedInitialMerchantShifts(merchantId: string): Promise<void> {
    // 1. Fetch active staff belonging to this workspace instance location
    const activeStaff = await this.getMerchantStaff(merchantId);
    if (activeStaff.length === 0) {
      console.log(`⚠️ Skip shift initialization for ${merchantId}: No active employee profiles found.`);
      return;
    }

    // 2. Pull operational rules matching businessHours configs
    const businessHours = await this.getBusinessHours(merchantId);
    const hoursMap = new Map<number, any>();
    businessHours.forEach(bh => {
      hoursMap.set(bh.dayOfWeek, bh); // 1 = Monday, 7 = Sunday
    });

    const shiftsToInitialize: Array<{ employeeId: string; date: string; startTime: string; endTime: string }> = [];
    const today = new Date();

    // 3. Cycle forward 90 days to establish future booking capacity pipelines
    for (let i = 0; i < 90; i++) {
      const targetDate = new Date();
      targetDate.setDate(today.getDate() + i);

      // Map JavaScript Sunday(0)-Saturday(6) to Database Monday(1)-Sunday(7)
      let dayOfWeekIdx = targetDate.getDay();
      if (dayOfWeekIdx === 0) dayOfWeekIdx = 7; 

      const dayConfig = hoursMap.get(dayOfWeekIdx);

      // Skip populating shifts if the day is closed
      if (dayConfig && dayConfig.isClosed) {
        continue;
      }

      const startTime = dayConfig?.openTime || "09:00";
      const endTime = dayConfig?.closeTime || "17:00";
      const formattedDate = targetDate.toISOString().split('T')[0]; // "YYYY-MM-DD"

      // Allocate every active team member to run execution routines during business uptime windows
      for (const staff of activeStaff) {
        shiftsToInitialize.push({
          employeeId: staff.id,
          date: formattedDate,
          startTime: startTime,
          endTime: endTime,
        });
      }
    }

    // 4. Hand off array data packages straight into our batch synchronization engine
    if (shiftsToInitialize.length > 0) {
      await this.synchronizeMerchantShifts(merchantId, shiftsToInitialize);
      console.log(`🚀 Initialized default operational matrix state for merchant ${merchantId}.`);
    }
  }

  // =========================================================================
  // 🔥 ATOMIC BATCH SYNCHRONIZATION FOR SHIFT CONFIGURATIONS
  // =========================================================================
  async synchronizeMerchantShifts(
    merchantId: string, 
    shiftsPayload: Array<{ employeeId: string; date: string; startTime: string; endTime: string }>
  ) {
    if (!shiftsPayload || shiftsPayload.length === 0) {
      await prisma.shift.deleteMany({
        where: { merchantId }
      });
      return [];
    }

    // Safely transform dates into standardized JS ISO midnight values for the DB engine
    const parsedShifts = shiftsPayload.map(shift => {
      const parsedDate = new Date(shift.date);
      const normalizedDate = new Date(Date.UTC(parsedDate.getFullYear(), parsedDate.getMonth(), parsedDate.getDate()));
      
      return {
        merchantId,
        employeeId: shift.employeeId,
        date: normalizedDate, // Safely maps to 'timestamp without time zone'
        startTime: shift.startTime || "09:00",
        endTime: shift.endTime || "17:00"
      };
    });

    // Determine the starting boundary (today) to clear old future schedules cleanly
    const datesArray = parsedShifts.map(s => s.date.getTime());
    const minDate = new Date(Math.min(...datesArray));

    // Run within an isolated, atomic transaction block
    return await prisma.$transaction(async (tx) => {
      // FIX: Purge ALL existing schedules from today forward to clean up obsolete look-ahead dates
      await tx.shift.deleteMany({
        where: {
          merchantId,
          date: {
            gte: minDate // Wipes out everything from today onwards
          }
        }
      });

      // 2. Perform mass writeback execution mapping to the updated structural matrix layout
      await tx.shift.createMany({
        data: parsedShifts,
        skipDuplicates: true
      });

      // Return newly written configurations back to caller
      return await tx.shift.findMany({
        where: {
          merchantId,
          date: {
            gte: minDate
          }
        },
        orderBy: { date: 'asc' }
      });
    });
  }
  // =========================================================================
  // 🟢 NEW: FETCH EXISTING SCHEDULED SHIFTS FOR MERCHANT
  // =========================================================================
  async getScheduledShifts(merchantId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    return await prisma.shift.findMany({
      where: {
        merchantId,
        date: {
          gte: today, // Fetch shifts from today onwards
        },
      },
      select: {
        employeeId: true,
        date: true,
        startTime: true,
        endTime: true,
      },
      orderBy: { date: 'asc' },
    });
  }
}