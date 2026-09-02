import 'dotenv/config';
import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import bookingRoutes from './routes/booking.routes';
import merchantRoutes from './routes/merchant.routes';
import stripeRoutes from './routes/stripe.routes';
import serviceRouter from './routes/service.routes';
import customerRouter from './routes/customer.routes';

(BigInt.prototype as any).toJSON = function () {
  return this.toString();
};

const app = express();
const PORT = Number(process.env.PORT) || 3000;

// Explicitly define origin list including exact render frontend URL
const allowedOrigins = [
  'http://localhost:3000',
  'https://pet-frontend-jfp4.onrender.com',
  ...(process.env.FRONTEND_URL ? process.env.FRONTEND_URL.split(',').map((url) => url.trim()) : [])
];

// Robust CORS Middleware
app.use(
  cors({
    origin: (origin, callback) => {
      // Allow non-browser requests (Postman, mobile) OR matching origins
      if (!origin || allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        console.warn(`CORS blocked for origin: ${origin}`);
        callback(null, false);
      }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
    optionsSuccessStatus: 200 // Legacy browser support for 204/200 preflight responses
  })
);

// Explicit Preflight Handler (Fixes Chrome Preflight CORS block)
app.options('*', (req: Request, res: Response) => {
  const origin = req.headers.origin;
  if (origin && allowedOrigins.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Access-Control-Allow-Credentials', 'true');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept');
  }
  res.sendStatus(200);
});

// Body Parser
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

// 404 Catch-all Handler
app.use((_req: Request, res: Response) => {
  res.status(404).json({ error: 'Route not found' });
});

// Global Error Handler - Ensures CORS headers are preserved during server crashes
app.use((err: any, req: Request, res: Response, _next: NextFunction) => {
  console.error('SERVER ERROR:', err);

  const origin = req.headers.origin;
  if (origin && allowedOrigins.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Access-Control-Allow-Credentials', 'true');
  }

  res.status(500).json({
    success: false,
    message: err.message || 'Internal Server Error',
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server listening on port ${PORT}`);
});