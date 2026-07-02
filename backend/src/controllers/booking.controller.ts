import { Request, Response } from 'express';
import { BookingService } from '../services/booking.service';
import { Gender } from '@prisma/client';
import prisma from '../services/db';


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
        message: 'Missing mandatory structural parameters: ownerId, speciesId, breed, or name.',
      });
      return;
    }
    
    const dogSpecies = await prisma.species.findUnique({
      where: { name: 'Dog' }
    });

    if (!dogSpecies) {
      res.status(500).json({
        success: false,
        message: "System configuration fault: 'Dog' species records are missing. Please execute 'npx prisma db seed' first.",
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

    res.status(201).json(result);
  } catch (error: any) {
    res.status(400).json({
      success: false,
      message: error.message || 'An internal file processing fault occurred.',
    });
  }
};