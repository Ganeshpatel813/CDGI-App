<<<<<<< HEAD
# CDGI Faculty Attendance — Flutter Mobile App

Full-stack attendance system with Flutter (Android/iOS) frontend and Flask + MySQL backend.

## Architecture

```
Flutter App (Android/iOS)
    ↕ HTTP (session cookie auth)
Flask Backend (Python)
    ↕ mysql-connector-python
MySQL Database
```

## Backend Setup

### 1. Install Python dependencies

```bash
cd pahal-main/Attendance-System-main

# Install base deps
pip install -r requirements.txt

# face_recognition requires cmake + dlib (may take a few minutes)
# On Windows: pip install cmake; pip install dlib; pip install face_recognition
# On Linux:   sudo apt install cmake libopenblas-dev liblapack-dev; pip install face_recognition
```

### 2. Configure MySQL

Edit `database.py` or set environment variables:

```bash
export MYSQL_HOST=localhost
export MYSQL_PORT=3306
export MYSQL_USER=root
export MYSQL_PASSWORD=your_password
export MYSQL_DATABASE=cdgi_attendance
```

### 3. Run the server

```bash
python app.py
```

The server starts on `http://0.0.0.0:5000`. Default admin credentials:
- **Employee ID:** `ADMIN001`
- **Password:** `admin@CDGI2025`

---

## Flutter App Setup

### 1. Set your server IP

Edit `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:5000';
```

Replace `YOUR_SERVER_IP` with your machine's local IP (e.g. `192.168.1.100`).

### 2. Install Flutter dependencies

```bash
cd flutter_attendance
flutter pub get
```

### 3. Run on Android/iOS

```bash
# Android
flutter run

# iOS (macOS only)
flutter run -d ios
```

---

## Features

| Feature | Description |
|---------|-------------|
| Login / Register | Employee ID + password + face scan |
| Face Verification | Server-side via `face_recognition` library |
| GPS Check | Must be within 50m of CDGI campus |
| Check-In / Check-Out | Multiple sessions per day supported |
| Dashboard | Today's status + monthly stats |
| Reports | Calendar view + attendance log |
| Admin Panel | Faculty management + attendance overview |

## API Endpoints Used by Mobile App

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | Login |
| POST | `/api/auth/logout` | Logout |
| GET | `/api/auth/me` | Get profile |
| POST | `/api/auth/register` | Register |
| GET | `/api/auth/check-empid` | Check ID availability |
| POST | `/api/location/validate` | Validate GPS location |
| POST | `/api/face/descriptor` | Compute face descriptor |
| POST | `/api/face/verify` | Verify face match |
| POST | `/api/attendance/check-in` | Check in |
| POST | `/api/attendance/check-out` | Check out |
| GET | `/api/attendance/today-status` | Today's status |
| GET | `/api/report/my` | Attendance records |
| GET | `/api/report/summary` | Monthly summary |
| GET | `/api/report/calendar` | Calendar data |
| GET | `/api/admin/stats` | Admin dashboard stats |
| GET | `/api/admin/faculty` | Faculty list |
| POST | `/api/admin/faculty/add` | Add faculty |
| DELETE | `/api/admin/faculty/:id` | Delete faculty |
| POST | `/api/admin/faculty/:id/toggle` | Activate/deactivate |
| GET | `/api/admin/attendance` | Attendance by date |
| GET | `/api/colleges` | College list |
=======
# CDGI-App
mobile app
>>>>>>> a0826727b65277fc936de8d5b68eb68d259683fd
