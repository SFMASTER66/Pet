import { Gender, PetStatus  } from '@prisma/client';
import prisma from './db';


// 定义创建宠物所需的严格 TypeScript 类型声明
interface CreatePetInput {
  ownerId: string;
  speciesId: number;
  breed: string;
  name: string;
  microchipNumber?: string;
  gender: Gender;
  isDesexed: boolean;
  dob?: string | Date; // 接受 ISO 字符串或 Date 对象
  behaviorTags?: string[];
  behaviorNotes?: string;
  merchantId: string;
}

export const BookingService = {
  /**
   * 🏗️ 创建宠物档案并绑定主人
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

    // 🔒 业务安全校验 1：如果填了澳洲微芯片号，检查是否在平台中被别的狗绑定了
    if (microchipNumber) {
      const existingPet = await prisma.pet.findUnique({
        where: { microchipNumber: microchipNumber.trim() },
      });
      if (existingPet) {
        throw new Error(`❌ 澳洲微芯片号 [${microchipNumber}] 已被其他宠物登记，请核对！`);
      }
    }

    // 🔒 业务安全校验 2：确保主人账户（User）在数据库中真实存在
    const ownerExists = await prisma.user.findUnique({
      where: { id: ownerId },
    });
    if (!ownerExists) {
      throw new Error(`❌ 找不到指定的用户 ID [${ownerId}]，无法绑定宠物主人。`);
    }

    // 🛠️ 数据格式化：将传入的 dob 转换为标准 Date 格式
    const parsedDob = dob ? new Date(dob) : null;

    // 💾 正式写入 PostgreSQL 数据库
    const newPet = await prisma.pet.create({
      data: {
        ownerId,
        speciesId,
        breed: breed.trim(),
        name: name.trim(),
        microchipNumber: microchipNumber ? microchipNumber.trim() : null,
        status: PetStatus.ACTIVE, // 默认活跃状态
        gender,
        isDesexed,
        dob: parsedDob,
        behaviorTags,
        behaviorNotes,
        merchantId,
      },
      // 同时把品种大类（Species）和主人信息（User）关联查询出来，方便直接返回给前端
      include: {
        species: true,
        owner: {
          select: { name: true, email: true, phoneNumber: true },
        },
      },
    });

    // 🧠 附加产物：动态计算当前宠物的精确年龄，返回给前端直接渲染
    let ageText = '未知年龄';
    if (parsedDob) {
      const now = new Date();
      let years = now.getFullYear() - parsedDob.getFullYear();
      let months = now.getMonth() - parsedDob.getMonth();
      
      if (months < 0) {
        years--;
        months += 12;
      }
      ageText = years > 0 ? `${years} 岁 ${months} 个月` : `${months} 个月`;
    }

    return {
      success: true,
      message: '🎉 宠物档案创建成功！',
      data: {
        ...newPet,
        formattedAge: ageText, // 👈 动态计算的年龄标签：例如 "2 岁 4 个月"
      },
    };
  },
};
