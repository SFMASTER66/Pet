import 'dotenv/config';
import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import bookingRoutes from './routes/booking.routes';
import merchantRoutes from './routes/merchant.routes';
import stripeRoutes from './routes/stripe.routes';
import serviceRouter from './routes/service.routes';
import customerRouter from './routes/customer.routes';

// Fix BigInt serialization for Prisma
(BigInt.prototype as any).toJSON = function () {
  return this.toString();
};

const app = express();
const PORT = Number(process.env.PORT) || 3000;

// CORS Configuration
const allowedOrigins = process.env.FRONTEND_URL
  ? process.env.FRONTEND_URL.split(',').map((url) => url.trim())
  : ['http://localhost:3000'];

app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin || allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(null, false);
      }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

// Preflight OPTIONS handler using Regex instead of wildcard '*'
app.options(/(.*)/, cors());

// Body Parser: Skip JSON parsing on Stripe webhook so raw body remains intact
app.use((req: Request, res: Response, next: NextFunction) => {
  if (req.originalUrl === '/api/v1/stripe/webhook') {
    next();
  } else {
    express.json()(req, res, next);
  }
});

// Routes
app.use('/api/v1', bookingRoutes);
app.use('/api/v1', merchantRoutes);
app.use('/api/v1', stripeRoutes);
app.use('/api/v1', serviceRouter);
app.use('/api/v1', customerRouter);

// Health check endpoint
app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'UP', message: 'Pet SaaS Backend is running!' });
});

// 404 Catch-all Handler (using Regex instead of '*')
app.use((_req: Request, res: Response) => {
  res.status(404).json({ error: 'Route not found' });
});

// Global Error Handler
app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
  console.error('Unhandled Error:', err.message || err);
  res.status(err.status || 500).json({
    error: process.env.NODE_ENV === 'production' ? 'Internal Server Error' : err.message,
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server listening on port ${PORT}`);
});