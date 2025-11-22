# Task Management App

Full-stack task management application with Node.js/TypeScript backend and Flutter mobile frontend.

## Visuals

### Demo Video
Watch the complete app demo: [Crud task app demo video 22-11-25.mp4](demo/Crud%20task%20app%20demo%20video%2022-11-25.mp4)

### Download APK
Download the release APK: [app-release.apk](demo/app-release.apk) (21MB)


### Screenshots

#### Authentication Screens
 <img src="demo/images/Screenshot 2025-11-22 141107.png" alt="Login Screen" width="300"/>
<img src="demo/images/Screenshot 2025-11-22 141112.png" alt="Register Screen" width="300"/>

#### Task Management
 <img src="demo/images/Screenshot 2025-11-22 141138.png" alt="Task Filters" width="300"/> <img src="demo/images/Screenshot 2025-11-22 141147.png" alt="Task Details" width="300"/>

#### Task Operations
<img src="demo/images/Screenshot 2025-11-22 141202.png" alt="Add Task" width="300"/> <img src="demo/images/Screenshot 2025-11-22 141209.png" alt="Edit Task" width="300"/> <img src="demo/images/Screenshot 2025-11-22 141225.png" alt="Task Status" width="300"/>

#### Additional Features
<img src="demo/images/Screenshot 2025-11-22 141237.png" alt="Search Tasks" width="300"/> <img src="demo/images/Screenshot 2025-11-22 141249.png" alt="Filter by Status" width="300"/> <img src="demo/images/Screenshot 2025-11-22 141318.png" alt="Task Management" width="300"/>




## Project Structure

```
crud_task/
├── backend/          # Node.js + TypeScript + Prisma backend
└── lib/              # Flutter mobile app
```

## Backend Setup

See [backend/README.md](backend/README.md) for detailed backend setup instructions.

Quick start:
```bash
cd backend
npm install
npm run prisma:generate
npm run prisma:db push  # or npm run prisma:migrate
npm run dev
```

The backend will run on `http://localhost:3000`

## Flutter Setup

### Prerequisites
- Flutter SDK installed
- Android Studio / VS Code with Flutter extensions
- Backend server running

### Configuration

1. **Update API Base URL** (Important!)
   
   Open `lib/config/api_config.dart` and update the `baseUrl`:
   
   - For Android Emulator: `http://10.0.2.2:3000/api`
   - For iOS Simulator: `http://localhost:3000/api`
   - For Physical Device: `http://YOUR_COMPUTER_IP:3000/api` (find IP with `ipconfig` on Windows or `ifconfig` on Mac/Linux)

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the App**
   ```bash
   flutter run
   ```

### Building Android APK

```bash
# Debug APK
flutter build apk

# Release APK
flutter build apk --release

# APK location: build/app/outputs/flutter-apk/app-release.apk
```

## Features

### Backend
- ✅ JWT Authentication (Access + Refresh Tokens)
- ✅ User Registration & Login
- ✅ Task CRUD Operations
- ✅ Pagination, Filtering, and Searching
- ✅ Secure Password Hashing (bcrypt)
- ✅ Input Validation

### Flutter App
- ✅ Login & Registration Screens
- ✅ Secure Token Storage
- ✅ Automatic Token Refresh
- ✅ Task List with ListView.builder
- ✅ Pull-to-Refresh
- ✅ Pagination (Infinite Scroll)
- ✅ Filter by Status
- ✅ Search Tasks
- ✅ Add, Edit, Delete, Toggle Tasks
- ✅ Error Handling with User-Friendly Messages
- ✅ Provider State Management

## Tech Stack

### Backend
- Node.js + TypeScript
- Express.js
- Prisma ORM
- SQLite (development) / PostgreSQL (production)
- JWT (jsonwebtoken)
- bcrypt

### Flutter
- Flutter SDK
- Provider (State Management)
- http (HTTP Client)
- flutter_secure_storage (Token Storage)

## API Endpoints

See [API_ENDPOINTS.md](API_ENDPOINTS.md) for complete API documentation.

### Authentication
- `POST /api/auth/register` - Register
- `POST /api/auth/login` - Login
- `POST /api/auth/refresh` - Refresh Token
- `POST /api/auth/logout` - Logout

### Tasks
- `GET /api/tasks` - Get tasks (with pagination, filtering, searching)
- `GET /api/tasks/:id` - Get task by ID
- `POST /api/tasks` - Create task
- `PATCH /api/tasks/:id` - Update task
- `DELETE /api/tasks/:id` - Delete task
- `PATCH /api/tasks/:id/toggle` - Toggle task status

## Development Notes

### Backend
- Database uses SQLite by default (easy setup)
- JWT tokens expire: Access (30 min), Refresh (7 days)
- All task endpoints require authentication
- Tasks are user-specific (filtered by userId)

### Flutter
- Uses Provider for state management
- Tokens stored securely with flutter_secure_storage
- Automatic token refresh on 401 errors
- Efficient rendering with ListView.builder
- Pull-to-refresh and infinite scroll implemented

## Troubleshooting

### Backend not connecting
- Ensure backend is running on port 3000
- Check CORS settings if accessing from different origin
- Verify DATABASE_URL in backend/.env

### Flutter can't connect to backend
- Update `baseUrl` in `lib/config/api_config.dart`
- For Android emulator, use `10.0.2.2` instead of `localhost`
- For physical device, use your computer's IP address
- Ensure backend CORS allows your Flutter app origin

### Token refresh issues
- Check JWT secrets in backend/.env
- Verify token expiration times
- Check network connectivity

## License

This project is for educational purposes.
