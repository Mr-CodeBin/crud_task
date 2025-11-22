import express, { Request, Response } from 'express';
import cors from 'cors';
import { config } from './config/env';
import { errorMiddleware } from './middleware/error.middleware';
import authRoutes from './routes/auth.routes';
import taskRoutes from './routes/task.routes';

const app = express();

// midd
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req: Request, res: Response) => {
  res.status(200).json({
    success: true,
    message: 'Server is running',
  });
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/tasks', taskRoutes);

// well, debug check routes
console.log('\n📋 Registered API Routes:');
console.log('  POST /api/auth/register');
console.log('  POST /api/auth/login');
console.log('  POST /api/auth/refresh');
console.log('  POST /api/auth/logout');
console.log('  GET  /api/tasks');
console.log('  POST /api/tasks');
console.log('  GET  /api/tasks/:id');
console.log('  PATCH /api/tasks/:id');
console.log('  DELETE /api/tasks/:id');
console.log('  PATCH /api/tasks/:id/toggle\n');

// 404 route
app.use((req: Request, res: Response) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
  });
});

// Error handling mid
app.use(errorMiddleware);

// ser work
const PORT = config.port;
app.listen(PORT, () => {
  console.log(`🚀 Server is running on http://localhost:${PORT}`);
  console.log(`📝 Environment: ${config.nodeEnv}`);
});

export default app;

