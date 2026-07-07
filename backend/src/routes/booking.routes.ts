import { Router } from 'express';
import { 
  registerBooking, 
  portalBooking, 
  fetchDropdownServices ,
  updateBooking
} from '../controllers/booking.controller';

const router = Router();

// Public Customer Facing Booking Entry Point
router.post('/bookings', registerBooking);

// Admin Portal Booking Entry Points
router.get('/bookings/services', fetchDropdownServices);
router.post('/bookings/add', portalBooking);
router.put('/bookings/update/:id', updateBooking);

export default router;