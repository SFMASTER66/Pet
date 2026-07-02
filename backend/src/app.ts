import 'dotenv/config'; // <-- ADD THIS AT LINE 1
import express from 'express';
import cors from 'cors';
import bookingRoutes from './routes/booking.routes';
import merchantRoutes from './routes/merchant.routes';
import stripeRoutes from './routes/stripe.routes';
// 引入你写好的两个控制器路由（这里需要看你控制器里是怎么导出的，假设它们导出的是路由或应用）
// 如果你的控制器里直接写了 app.post，通常我们会把 app 实例传过去，或者使用 express.Router()。
// 这里先写一个最基础的启动监听：

(BigInt.prototype as any).toJSON = function () {
  return this.toString();
};

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// CRITICAL: Put global express.json() BELOW specific raw routes or omit it entirely 
// if you are handling body parsing inside individual routers, otherwise it might 
// conflict with Stripe's raw data signature validation.

app.use((req, res, next) => {
  if (req.originalUrl === '/api/v1/stripe/webhook') {
    next();
  } else {
    express.json()(req, res, next);
  }
});

app.use('/api/v1', bookingRoutes);
app.use('/api/v1', merchantRoutes);
app.use('/api/v1', stripeRoutes);

// 基础测试路由
app.get('/health', (req, res) => {
  res.json({ status: 'UP', message: 'Pet SaaS Backend is running!' });
});

// app.listen(PORT, () => {
//   console.log(`🚀 Server is happily running on http://localhost:${PORT}`);
// });


app.listen(Number(PORT), '0.0.0.0', () => {
  console.log(`🚀 Server is happily running on http://127.0.0.1:${PORT}`);
});