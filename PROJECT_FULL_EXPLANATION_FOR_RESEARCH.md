# Busify Project - Full Technical Explanation (for AI Research)

This document summarizes the full Busify system as it currently exists across repositories, including architecture, modules, APIs, flows, and recent behavior decisions.

---

## 1) Project Idea and Product Scope

Busify is a **school bus tracking and attendance platform** with four main roles:

- **System Admin**: manages school admins
- **School Admin**: manages buses, drivers, supervisors, parents, students, and dashboards
- **Supervisor (mobile app)**: starts trips, sends live location, scans students (face/QR/manual) and records attendance
- **Parent (mobile app / APIs)**: follows child trip status and notifications

Core goals:

- Real-time bus visibility
- Attendance integrity (face + supervisor confirmation)
- Parent/school operational coordination
- Bus roster and route handling per trip

---

## 2) Repositories and Their Responsibilities

### A) `busify_backend` (ASP.NET Core 8 + EF Core + SQL Server)

Main backend API and business logic:

- JWT authentication and role authorization
- CRUD and workflow endpoints for school operations
- Trip and live-location ingestion/queries
- Face attendance workflow orchestration
- Notification system
- EF migrations and DB model

Entry point:

- `src/API/Program.cs`
  - Configures auth, JSON, CORS, Swagger
  - Registers facematch HTTP client
  - Applies migrations at startup
  - Seeds default system admin if missing
  - Adds `/health/build` for deployment version checks

### B) `busify_frontend` (React + Vite + Tailwind + Bootstrap + Leaflet)

School admin web dashboard:

- Auth/login and protected app routing
- Management pages for supervisors/drivers/buses/parents/students/trips
- Live trip tracking map(s) with Leaflet + OpenStreetMap
- Notification bell and profile management
- Dark mode UI and responsive layouts

### C) `application` (Flutter mobile app)

Primarily supervisor and parent-facing app:

- Trip operations
- Camera capture and attendance interactions
- Face identify + confirm flow
- Live trip ETA/route UI

Main file:

- `lib/main.dart` uses theme controller + splash entry

### D) `face_recognition_project` (FastAPI + InsightFace ONNX service)

External face recognition microservice:

- `/embed` to generate face embeddings from images
- `/match` for 1:N identification against candidate embeddings
- Thresholded cosine similarity matching
- Returns `matchFound`, `matchedStudentId`, `confidence`, `topCandidates`, status

This service is consumed by backend through `IFaceRecognitionService`.

---

## 3) High-Level Architecture

1. Supervisor app captures photo / location.
2. App calls backend (`/v1/Supervisor/...`).
3. Backend:
   - reads trip context from SQL
   - builds candidate gallery from enrolled student face profiles
   - calls facematch service for identity
   - applies business rules (confidence/bus membership/expected student checks)
   - returns match state and message
4. App shows confirmation/no-match UI.
5. On confirm, backend writes attendance record + summary.
6. School admin web pages poll live trip endpoints to draw fleet maps and details.

---

## 4) Data and Domain Concepts

Important entities:

- `SchoolAdmin`, `Bus`, `Driver`, `Supervisor`, `Parent`, `Student`, `Trip`
- `LiveLocation` (telemetry points per trip)
- `Attendance` (scan records IN/OUT)
- `FaceRecognitionAttempt` (identify attempts metadata)
- `StudentFaceProfile` (stored embedding + profile image metadata)
- `Notification` (admin/parent alerts)

Trip status/type:

- `TripStatus`: e.g. NotStarted / Started / Ended
- `TripType`: Morning / Afternoon

---

## 5) Authentication and Access Control

Backend:

- JWT bearer auth
- Role-based `[Authorize(Roles = "...")]`

Frontend:

- Route guard component (`RequireAuth`)
- Checks token/user existence and token expiry (`exp`)
- Invalid sessions are cleared and redirected to `/login`

Purpose: prevent direct URL bypass (e.g. `/dashboard`) without valid auth.

---

## 6) Face Attendance System (Most Important Workflow)

## 6.1 Enrollment

- Student profile image can be provided during parent registration.
- Backend stores photo URL and attempts embedding generation through facematch service.
- Embedding stored in `StudentFaceProfile`.

## 6.2 Identify + Confirm contract

Documented in:

- `FACE_ATTENDANCE_CONTRACTS.md`
- `FACE_ATTENDANCE_ROLLOUT.md`

Flow:

1. `POST /v1/Supervisor/attendance/face-identify`
2. Backend evaluates result + business rules
3. App shows match/no-match state
4. `POST /v1/Supervisor/attendance/face-confirm` only if supervisor confirms

## 6.3 Business rules currently implemented

- No-match must stay no-match (client no longer auto-picks top candidate).
- If confidence is too low -> no match.
- If identified student is not on this trip bus -> `"This student is not in this bus"`.
- A secondary school-wide face pass can detect cross-bus student identity when needed.
- Confirmation disabled in UI for no-match state.

---

## 7) School Admin Web - Main Functional Areas

### 7.1 Dashboard (`/dashboard`)

- Cards/charts driven by backend summary endpoint
- Shortcuts module with navigation to core pages

### 7.2 Management Pages

- Supervisors
- Drivers
- Buses
- Students
- Parents / ParentRequest
- Trips

These pages use `schoolAdminService.js` wrappers over backend endpoints.

### 7.3 Live Tracking

Two levels:

1. **Fleet map** (`/track-trips`):
   - all started trips with bus markers
   - per-trip trail color
   - sticky detail panel on marker click
   - "Track this bus" filters others in same map

2. **Single bus/trip map**:
   - focused live tracking UI
   - route to destination and metadata cards

Map stack:

- `react-leaflet`
- OpenStreetMap tiles
- OSRM routing API for road-constrained polyline

---

## 8) Backend Endpoints Added/Used for Current Web UX

Key school admin endpoints:

- `GET /v1/SchoolAdmin/me`
- `GET /v1/SchoolAdmin/dashboard/summary`
- `GET /v1/SchoolAdmin/trips/today-board`
- `GET /v1/SchoolAdmin/trips/live-map`
- `GET /v1/SchoolAdmin/buses/{busId}/track`
- Notifications:
  - `GET /v1/SchoolAdmin/notifications`
  - `PATCH /v1/SchoolAdmin/notifications/{id}/read`

`trips/live-map` currently provides per started trip:

- bus/trip identifiers
- driver/supervisor names
- total students and IN attendance
- latest point
- trail points
- destination info (lat/lng/type/label)

---

## 9) Parent Creation and Approval Behavior

`POST /v1/parent/register` is used by both public parent flow and school-admin flow.

Current logic:

- If created by **school_admin role**, parent is auto-approved.
- If public flow, parent stays pending and admin notification is created.
- Child payload supports optional `busNumber` to auto-assign bus at creation.
- Add-parent UI supports multiple children and child removal.

---

## 10) UX/Styling State

Implemented platform-wide improvements:

- Global dark mode foundation via `html.dark` styles and persisted theme
- Notification badge positioning fix
- Responsive spacing/table overflow improvements on major pages
- Track map page adjusted toward full viewport behavior
- OpenStreetMap attribution bar hidden in UI

Known technical notes:

- Some bundles are still large in production build (Vite warning on chunk size).
- Dark mode is functional globally but can still be refined page-by-page for perfect polish.

---

## 11) Mobile App Notes (Flutter `application`)

The mobile app uses:

- Theme controller + splash bootstrap
- Supervisor trip screen with live map/ETA logic
- Face identify integration with backend
- Confirm/no-match attendance screen behavior

Important integration decision:

- No-match responses are not auto-promoted to success.
- Confirmation is blocked until a valid matched student exists.

---

## 12) Face Service (`face_recognition_project`) Notes

FastAPI service exposes:

- `POST /embed` (image -> embedding)
- `POST /match` (probe image vs candidate embeddings)

Model characteristics:

- InsightFace ONNX
- cosine similarity scoring
- configurable threshold via env (e.g. `FACE_MIN_COSINE_SIM`)

Backend wraps this service and applies additional domain constraints.

---

## 13) Typical End-to-End Scenario

1. School admin configures bus/driver/supervisor and student roster.
2. Parent/student profiles exist with face photos and embeddings.
3. Supervisor starts trip and app begins live location updates.
4. Supervisor scans student:
   - backend identifies face
   - if matched and valid, confirm attendance
   - if wrong/no match, UI blocks confirm and requires rescan/manual fallback
5. Admin sees fleet on Track Trips map with live movement, destinations, and attendance counts.
6. Parent/admin notifications are updated according to events.

---

## 14) Suggested Prompt Seed for Another AI

If you want to continue this project in another AI, provide:

1. This file.
2. These repositories:
   - `busify_backend`
   - `busify_frontend`
   - `application`
   - `face_recognition_project`
3. Ask it to keep behavior constraints:
   - no false confirm in face flow
   - bus-membership validation for identity
   - protected routes without login bypass
   - consistent dark mode and responsive UX
   - road-based route lines on map when destination exists

---

## 15) File and Contract References

- `busify_backend/src/API/Program.cs`
- `busify_backend/src/API/Controllers/SchoolAdminController.cs`
- `busify_backend/src/API/Controllers/SupervisorController.cs`
- `busify_backend/src/API/Controllers/ParentController.cs`
- `busify_backend/FACE_ATTENDANCE_CONTRACTS.md`
- `busify_backend/FACE_ATTENDANCE_ROLLOUT.md`
- `busify_frontend/src/api/schoolAdminService.js`
- `busify_frontend/src/pages/TrackTrips/TrackTrips.jsx`
- `application/lib/main.dart`
- `face_recognition_project/render_api/main.py`

