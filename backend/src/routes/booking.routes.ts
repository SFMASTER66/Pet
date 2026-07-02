import { Router } from 'express';
import { registerBooking } from '../controllers/booking.controller';

const router = Router();

// This will catch POST requests sent to /pets
router.post('/bookings', registerBooking);

export default router;