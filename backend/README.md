# Backend API - Task Management System

Node.js + TypeScript + Prisma backend with JWT authentication.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Set up environment variables:
   - Create `.env` file with the following variables:
   - `DATABASE_URL` - Database connection string (default: `file:./prisma/dev.db`)
   - `JWT_ACCESS_SECRET` - Secret for access tokens (min 32 characters)
   - `JWT_REFRESH_SECRET` - Secret for refresh tokens (min 32 characters)
   - `JWT_ACCESS_EXPIRES_IN` - Access token expiration in seconds (default: 1800)
   - `JWT_REFRESH_EXPIRES_IN` - Refresh token expiration in seconds (default: 604800)
   - `PORT` - Server port (default: 3000)
   - `NODE_ENV` - Environment (development/production)

3. Initialize database:
```bash
npm run prisma:migrate
```

4. Generate Prisma Client:
```bash
npm run prisma:generate
```

## Running the Server

### Development mode (with auto-reload):
```bash
npm run dev
```

### Production mode:
```bash
npm run build
npm start
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/refresh` - Refresh access token
- `POST /api/auth/logout` - Logout user

### Tasks (Requires Authentication)
- `GET /api/tasks` - Get tasks (with pagination, filtering, searching)
- `GET /api/tasks/:id` - Get task by ID
- `POST /api/tasks` - Create new task
- `PATCH /api/tasks/:id` - Update task
- `DELETE /api/tasks/:id` - Delete task
- `PATCH /api/tasks/:id/toggle` - Toggle task status

## Database

Uses SQLite by default (easy setup). For production, consider PostgreSQL or MySQL.

To view database:
```bash
npm run prisma:studio
```

## Environment Variables

- `DATABASE_URL` - Database connection string
- `JWT_ACCESS_SECRET` - Secret for access tokens
- `JWT_REFRESH_SECRET` - Secret for refresh tokens
- `JWT_ACCESS_EXPIRES_IN` - Access token expiration (seconds)
- `JWT_REFRESH_EXPIRES_IN` - Refresh token expiration (seconds)
- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment (development/production)

