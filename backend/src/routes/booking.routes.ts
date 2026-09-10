import { Router } from 'express';
import { 
  portalBooking, 
  fetchDropdownServices ,
  updateBooking,
  removeBooking,
  fetchAvailableSlots,
  fetchAdminAvailableSlots,
  removeAppointmentAddOn
} from '../controllers/booking.controller';
import { requestLogger } from '../middlewares/activity-log.middleware';

const router = Router();

// Admin Portal Booking Entry Points
router.get('/bookings/services', fetchDropdownServices);
router.get('/bookings/available-slots', fetchAvailableSlots);
router.get('/bookings/admin/available-slots', fetchAdminAvailableSlots);
router.post('/bookings/add', requestLogger as any, portalBooking);
router.put('/bookings/update/:id', requestLogger as any, updateBooking);
router.delete('/bookings/delete/:id', requestLogger as any, removeBooking);
router.delete('/bookings/appointments/add-ons/:appointmentAddOnId', requestLogger as any, removeAppointmentAddOn);

export default router;