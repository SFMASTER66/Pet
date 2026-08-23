import { Router } from 'express';
import { 
  registerBooking, 
  portalBooking, 
  fetchDropdownServices ,
  updateBooking,
  removeBooking,
  fetchAvailableSlots,
  fetchAdminAvailableSlots,
  removeAppointmentAddOn
} from '../controllers/booking.controller';

const router = Router();

// Public Customer Facing Booking Entry Point
router.post('/bookings', registerBooking);

// Admin Portal Booking Entry Points
router.get('/bookings/services', fetchDropdownServices);
router.get('/bookings/available-slots', fetchAvailableSlots);
router.get('/bookings/admin/available-slots', fetchAdminAvailableSlots);
router.post('/bookings/add', portalBooking);
router.put('/bookings/update/:id', updateBooking);
router.delete('/bookings/delete/:id', removeBooking);
router.delete('/bookings/appointments/add-ons/:appointmentAddOnId', removeAppointmentAddOn);

export default router;