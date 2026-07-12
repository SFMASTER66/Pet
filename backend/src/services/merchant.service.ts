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

    const whereClause: any = {
      merchantId: merchantId,
    };

    if (search && search.length > 0) {
      whereClause.AND = [
        {
          OR: [
            { name: { contains: search, mode: 'insensitive' } },  
            { breed: { contains: search, mode: 'insensitive' } }, 
            {
              owner: {
                OR: [
                  { name: { contains: search, mode: 'insensitive' } },        
                  { email: { contains: search, mode: 'insensitive' } },       
                  { phoneNumber: { contains: search, mode: 'insensitive' } }, 
                ],
              },
            },
          ],
        },
      ];
    }

    const [records, totalCount] = await prisma.$transaction([
      prisma.pet.findMany({
        where: whereClause, 
        skip: skip,
        take: limit,
        include: {
          owner: true, 
          // ==========================================
          // 🔥 NEW: AGGREGATE COUNT RELATION FOR APPOINTMENTS
          // ==========================================
          _count: {
            select: { appointments: true }
          }
        },
        orderBy: {
          name: 'asc',
        },
      }),
      prisma.pet.count({
        where: whereClause, 
      }),
    ]);

    const formattedRecords = records.map((pet: any) => ({
      id: pet.id,
      name: pet.name,
      breed: pet.breed || 'N/A',
      gender: pet.gender || 'MALE',
      isDesexed: pet.isDesexed || false,
      notes: pet.behaviorNotes || null,
      // ==========================================
      // 🔥 NEW: MAP THE APPOINTMENT COUNT TO UI PAYLOAD
      // ==========================================
      appointmentCount: pet._count?.appointments ?? 0,
      owner: {
        name: pet.owner?.name || 'Unknown Owner',
        email: pet.owner?.email || 'No contact email listed',
        phone: pet.owner?.phoneNumber || 'N/A',
      },
    }));

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
}