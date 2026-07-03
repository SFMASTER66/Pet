import prisma from './db';
import { UserRole } from '@prisma/client';
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
  // New method to fetch live service matrices from Prisma
  async getServiceMatrices(merchantId: string) {
    return await prisma.servicePricingMatrix.findMany({
      where: { merchantId },
      orderBy: { name: 'asc' }
    });
  }

  async getDashboardData(merchantId: string): Promise<MerchantDashboardData> {
    // 1. Fetch data from Prisma using the correct relation names
    const appointments = await prisma.appointment.findMany({
      where: { merchantId, status: 'PAID' },
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

    // 2. Cast to any safely inside the map iteration to eliminate strict Prisma compilation errors
    const appointmentsList = appointments.map((app: any) => {
      const priceCents = app.priceCentsAud || 0;
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
        price: priceCents / 100 
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

  async getMerchantStaff(merchantId: string) {
    return await prisma.user.findMany({
      where: {
        merchantId: merchantId,
        role: UserRole.MERCHANT_STAFF,
      },
      select: { id: true, name: true, email: true, role: true }
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

    const staffUser = await prisma.user.create({
      data: {
        email: data.email,
        passwordHash: hashedPassword,
        name: data.name,
        role: UserRole.MERCHANT_STAFF,
        merchantId: data.merchantId,
      },
    });

    return {
      id: staffUser.id,
      name: staffUser.name,
      email: staffUser.email,
      role: staffUser.role,
    };
  }

  async removeStaffAccount(staffId: string, merchantId: string) {
    return await prisma.user.deleteMany({
      where: {
        id: staffId,
        merchantId: merchantId, 
        role: UserRole.MERCHANT_STAFF
      }
    });
  }
}