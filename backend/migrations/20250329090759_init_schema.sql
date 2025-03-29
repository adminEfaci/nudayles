-- +goose Up
-- +goose StatementBegin
SELECT 'up SQL query';

-- Enums
CREATE TYPE "UserRole" AS ENUM ('SUPER_ADMIN', 'ADMIN', 'DISPATCHER', 'DRIVER', 'LOADER', 'TECHNICIAN', 'SUPERVISOR', 'PROVIDER', 'VIEWER', 'AUDITOR', 'SYSTEM');
CREATE TYPE "CrewStatus" AS ENUM ('ACTIVE', 'INACTIVE', 'ON_BREAK', 'MAINTENANCE', 'TRAINING', 'EMERGENCY');
CREATE TYPE "ShiftType" AS ENUM ('MORNING', 'AFTERNOON', 'NIGHT', 'GRAVEYARD', 'CUSTOM');
CREATE TYPE "TruckType" AS ENUM ('COMPACTOR', 'DUMP_TRUCK', 'ROLL_OFF', 'FRONT_LOADER', 'SIDE_LOADER', 'TANKER', 'FLATBED', 'DUAL_STREAM');
CREATE TYPE "TruckStatus" AS ENUM ('ACTIVE', 'MAINTENANCE', 'OUT_OF_SERVICE', 'RETIRED', 'RESERVED', 'CLEANING');
CREATE TYPE "DriverStatus" AS ENUM ('ACTIVE', 'ON_LEAVE', 'INACTIVE', 'SUSPENDED', 'TERMINATED', 'IN_TRAINING');
CREATE TYPE "LoaderStatus" AS ENUM ('ACTIVE', 'ON_LEAVE', 'INACTIVE', 'SUSPENDED', 'TERMINATED', 'IN_TRAINING');
CREATE TYPE "MaterialType" AS ENUM ('WASTE', 'RECYCLING_FIBRE', 'RECYCLING_CONTAINERS', 'YARD_WASTE', 'ORGANICS', 'HAZARDOUS', 'CONSTRUCTION', 'MIXED', 'LARGE_ITEM');
CREATE TYPE "DayOfWeek" AS ENUM ('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY');
CREATE TYPE "WeekType" AS ENUM ('REGULAR', 'HOLIDAY', 'EVENT', 'SEASONAL', 'PEAK', 'OFF_PEAK');
CREATE TYPE "RecycleWeek" AS ENUM ('A', 'B');
CREATE TYPE "AssignmentStatus" AS ENUM ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'DELAYED', 'CANCELLED', 'FAILED', 'REROUTED');
CREATE TYPE "ScheduleStatus" AS ENUM ('DRAFT', 'FINALIZED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'ARCHIVED', 'OPTIMIZED');
CREATE TYPE "TimeSlot" AS ENUM ('EIGHT_AM', 'ELEVEN_AM', 'TWO_PM', 'FIVE_PM', 'CUSTOM', 'URGENT');
CREATE TYPE "AttendanceStatus" AS ENUM ('PRESENT', 'ABSENT', 'LATE', 'LEAVE', 'SICK', 'VACATION', 'NO_SHOW');
CREATE TYPE "IssueCategory" AS ENUM ('COLLECTION', 'INTERNAL');
CREATE TYPE "CollectionType" AS ENUM ('WASTE', 'RECYCLE');
CREATE TYPE "WasteIssueType" AS ENUM ('OVERSIZED_BAG', 'NO_TAGS', 'BAG_LIMIT_EXCEED', 'HAZARDOUS_MATERIAL', 'NOTHING_OUT', 'OTHER');
CREATE TYPE "RecycleIssueType" AS ENUM ('RECYCLE_IN_BAGS', 'WRONG_COLLECTION_WEEK', 'NOTHING_OUT', 'OTHER');
CREATE TYPE "InternalIssueType" AS ENUM ('FLEET_ISSUE', 'TRUCK_ISSUE', 'PERSONNEL_ISSUE', 'OTHER');
CREATE TYPE "IssueStatus" AS ENUM ('PENDING', 'REVIEWED', 'RESOLVED');
CREATE TYPE "ResolutionType" AS ENUM ('RESOLVED_INTERNALLY', 'RESOLVED_EXTERNALLY', 'DOCUMENTED');

-- User Table
CREATE TABLE "User" (
  "id" VARCHAR(36) PRIMARY KEY,
  "email" VARCHAR(255) UNIQUE NOT NULL,
  "username" VARCHAR(255) UNIQUE NOT NULL,
  "fullName" VARCHAR(255) NOT NULL,
  "hashedPassword" VARCHAR(255) NOT NULL,
  "role" "UserRole" NOT NULL DEFAULT 'VIEWER',
  "permissions" TEXT,
  "hashedQuickCode" VARCHAR(255) UNIQUE,
  "quickCode" VARCHAR(255) UNIQUE,
  "quickCodeExpires" TIMESTAMP,
  "archived" BOOLEAN NOT NULL DEFAULT false,
  "mfaSecret" VARCHAR(255),
  "mfaEnabled" BOOLEAN NOT NULL DEFAULT false,
  "recoveryCodes" TEXT NOT NULL,
  "resetToken" VARCHAR(255) UNIQUE,
  "resetTokenExpiry" TIMESTAMP,
  "lastLogin" TIMESTAMP,
  "loginAttempts" INTEGER NOT NULL DEFAULT 0,
  "lockedUntil" TIMESTAMP,
  "preferences" TEXT,
  "notificationSettings" JSONB,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL
);
CREATE INDEX "User_createdAt_idx" ON "User" ("createdAt");
CREATE INDEX "User_updatedAt_idx" ON "User" ("updatedAt");

-- ConfigSetting Table
CREATE TABLE "ConfigSetting" (
  "id" VARCHAR(36) PRIMARY KEY,
  "key" VARCHAR(255) UNIQUE NOT NULL,
  "value" TEXT NOT NULL,
  "isSecret" BOOLEAN NOT NULL DEFAULT false,
  "category" VARCHAR(255) NOT NULL,
  "description" TEXT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  "createdBy" VARCHAR(255) NOT NULL,
  "updatedBy" VARCHAR(255) NOT NULL
);
CREATE INDEX "ConfigSetting_key_idx" ON "ConfigSetting" ("key");
CREATE INDEX "ConfigSetting_createdAt_idx" ON "ConfigSetting" ("createdAt");
CREATE INDEX "ConfigSetting_updatedAt_idx" ON "ConfigSetting" ("updatedAt");

-- Session Table
CREATE TABLE "Session" (
  "id" VARCHAR(36) PRIMARY KEY,
  "userId" VARCHAR(36) NOT NULL,
  "refreshToken" VARCHAR(255) UNIQUE NOT NULL,
  "expiresAt" TIMESTAMP NOT NULL,
  "revokedAt" TIMESTAMP,
  "ipAddress" VARCHAR(255),
  "userAgent" TEXT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  "previousSessionId" VARCHAR(36),
  "securityContext" JSONB,
  FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("previousSessionId") REFERENCES "Session" ("id")
);
CREATE INDEX "Session_userId_idx" ON "Session" ("userId");
CREATE INDEX "Session_expiresAt_idx" ON "Session" ("expiresAt");
CREATE INDEX "Session_revokedAt_idx" ON "Session" ("revokedAt");
CREATE INDEX "Session_previousSessionId_idx" ON "Session" ("previousSessionId");

-- AuditLog Table
CREATE TABLE "AuditLog" (
  "id" VARCHAR(36) PRIMARY KEY,
  "action" VARCHAR(255) NOT NULL,
  "entityType" VARCHAR(255) NOT NULL,
  "entityId" VARCHAR(36) NOT NULL,
  "userId" VARCHAR(36),
  "details" TEXT,
  "ipAddress" VARCHAR(255),
  "userAgent" TEXT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE SET NULL
);
CREATE INDEX "AuditLog_createdAt_idx" ON "AuditLog" ("createdAt");
CREATE INDEX "AuditLog_userId_idx" ON "AuditLog" ("userId");

-- Driver Table
CREATE TABLE "Driver" (
  "id" VARCHAR(36) PRIMARY KEY,
  "userId" VARCHAR(36) UNIQUE NOT NULL,
  "licenseType" VARCHAR(255) NOT NULL,
  "licenseNumber" VARCHAR(255) UNIQUE NOT NULL,
  "licenseExpiry" TIMESTAMP NOT NULL,
  "cellNumber" VARCHAR(255),
  "address" TEXT,
  "status" "DriverStatus" NOT NULL DEFAULT 'ACTIVE',
  "emergencyContact" TEXT,
  "notes" TEXT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE
);
CREATE INDEX "Driver_createdAt_idx" ON "Driver" ("createdAt");
CREATE INDEX "Driver_updatedAt_idx" ON "Driver" ("updatedAt");

-- Loader Table
CREATE TABLE "Loader" (
  "id" VARCHAR(36) PRIMARY KEY,
  "userId" VARCHAR(36) UNIQUE NOT NULL,
  "pickupSpot" VARCHAR(255) NOT NULL,
  "cellNumber" VARCHAR(255),
  "status" "LoaderStatus" NOT NULL DEFAULT 'ACTIVE',
  "emergencyContact" TEXT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE
);
CREATE INDEX "Loader_createdAt_idx" ON "Loader" ("createdAt");
CREATE INDEX "Loader_updatedAt_idx" ON "Loader" ("updatedAt");

-- Truck Table
CREATE TABLE "Truck" (
  "id" VARCHAR(36) PRIMARY KEY,
  "vin" VARCHAR(255) UNIQUE NOT NULL,
  "tagNumber" VARCHAR(255) UNIQUE NOT NULL,
  "type" "TruckType" NOT NULL,
  "status" "TruckStatus" NOT NULL DEFAULT 'ACTIVE',
  "capacity" FLOAT NOT NULL,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL
);
CREATE INDEX "Truck_vin_idx" ON "Truck" ("vin");
CREATE INDEX "Truck_tagNumber_idx" ON "Truck" ("tagNumber");
CREATE INDEX "Truck_createdAt_idx" ON "Truck" ("createdAt");
CREATE INDEX "Truck_updatedAt_idx" ON "Truck" ("updatedAt");

-- Crew Table
CREATE TABLE "Crew" (
  "id" VARCHAR(36) PRIMARY KEY,
  "primaryDriverId" VARCHAR(36) UNIQUE NOT NULL,
  "truckId" VARCHAR(36) NOT NULL,
  "status" "CrewStatus" NOT NULL DEFAULT 'ACTIVE',
  "shift" "ShiftType" NOT NULL DEFAULT 'MORNING',
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  FOREIGN KEY ("primaryDriverId") REFERENCES "Driver" ("id"),
  FOREIGN KEY ("truckId") REFERENCES "Truck" ("id")
);
CREATE INDEX "Crew_createdAt_idx" ON "Crew" ("createdAt");
CREATE INDEX "Crew_updatedAt_idx" ON "Crew" ("updatedAt");

-- CrewLoader Table (many-to-many)
CREATE TABLE "CrewLoader" (
  "crewId" VARCHAR(36) NOT NULL,
  "loaderId" VARCHAR(36) NOT NULL,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("crewId", "loaderId"),
  FOREIGN KEY ("crewId") REFERENCES "Crew" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("loaderId") REFERENCES "Loader" ("id") ON DELETE CASCADE
);
CREATE INDEX "CrewLoader_createdAt_idx" ON "CrewLoader" ("createdAt");

-- TruckMaintenance Table
CREATE TABLE "TruckMaintenance" (
  "id" VARCHAR(36) PRIMARY KEY,
  "truckId" VARCHAR(36) NOT NULL,
  "date" TIMESTAMP NOT NULL,
  "description" TEXT NOT NULL,
  "cost" FLOAT,
  "odometerReading" FLOAT,
  "completedBy" VARCHAR(255),
  "recordedBy" VARCHAR(255) NOT NULL,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  FOREIGN KEY ("truckId") REFERENCES "Truck" ("id")
);
CREATE INDEX "TruckMaintenance_truckId_idx" ON "TruckMaintenance" ("truckId");
CREATE INDEX "TruckMaintenance_date_idx" ON "TruckMaintenance" ("date");
CREATE INDEX "TruckMaintenance_createdAt_idx" ON "TruckMaintenance" ("createdAt");

-- Municipality Table
CREATE TABLE "Municipality" (
  "id" VARCHAR(36) PRIMARY KEY,
  "name" VARCHAR(255) UNIQUE NOT NULL,
  "serviceDays" TEXT NOT NULL,
  "materialTypes" TEXT NOT NULL,
  "contactPersons" TEXT,
  "address" TEXT,
  "notes" TEXT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL
);
CREATE INDEX "Municipality_name_idx" ON "Municipality" ("name");
CREATE INDEX "Municipality_createdAt_idx" ON "Municipality" ("createdAt");
CREATE INDEX "Municipality_updatedAt_idx" ON "Municipality" ("updatedAt");

-- Assignment Table
CREATE TABLE "Assignment" (
  "id" VARCHAR(36) PRIMARY KEY,
  "route" VARCHAR(255) NOT NULL,
  "materialType" "MaterialType" NOT NULL,
  "scheduledDate" TIMESTAMP NOT NULL,
  "status" "AssignmentStatus" NOT NULL DEFAULT 'SCHEDULED',
  "municipalityId" VARCHAR(36) NOT NULL,
  "weekNumber" INTEGER NOT NULL,
  "dayOfWeek" "DayOfWeek" NOT NULL,
  "weekType" "WeekType" NOT NULL DEFAULT 'REGULAR',
  "difficultyScore" FLOAT,
  "dualStreamPriority" FLOAT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  FOREIGN KEY ("municipalityId") REFERENCES "Municipality" ("id")
);
CREATE INDEX "Assignment_municipalityId_idx" ON "Assignment" ("municipalityId");
CREATE INDEX "Assignment_scheduledDate_idx" ON "Assignment" ("scheduledDate");
CREATE INDEX "Assignment_createdAt_idx" ON "Assignment" ("createdAt");

-- AssignmentUpdate Table
CREATE TABLE "AssignmentUpdate" (
  "id" VARCHAR(36) PRIMARY KEY,
  "assignmentId" VARCHAR(36) NOT NULL,
  "timeSlot" "TimeSlot" NOT NULL,
  "completion" FLOAT NOT NULL DEFAULT 0.0,
  "comments" TEXT,
  "supervisorId" VARCHAR(36),
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  FOREIGN KEY ("assignmentId") REFERENCES "Assignment" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("supervisorId") REFERENCES "User" ("id") ON DELETE SET NULL
);
CREATE INDEX "AssignmentUpdate_assignmentId_idx" ON "AssignmentUpdate" ("assignmentId");
CREATE INDEX "AssignmentUpdate_supervisorId_idx" ON "AssignmentUpdate" ("supervisorId");
CREATE INDEX "AssignmentUpdate_createdAt_idx" ON "AssignmentUpdate" ("createdAt");

-- DailySchedule Table
CREATE TABLE "DailySchedule" (
  "id" VARCHAR(36) PRIMARY KEY,
  "date" TIMESTAMP NOT NULL,
  "weekNumber" INTEGER NOT NULL,
  "dayOfWeek" "DayOfWeek" NOT NULL,
  "weekType" "WeekType" NOT NULL DEFAULT 'REGULAR',
  "recycleWeek" "RecycleWeek" NOT NULL,
  "materialType" "MaterialType" NOT NULL,
  "crewId" VARCHAR(36) NOT NULL,
  "requiredDrivers" INTEGER NOT NULL DEFAULT 1,
  "requiredLoaders" INTEGER NOT NULL DEFAULT 1,
  "requiredTrucks" INTEGER NOT NULL DEFAULT 1,
  "status" "ScheduleStatus" NOT NULL DEFAULT 'DRAFT',
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  "truckId" VARCHAR(36),
  "notes" TEXT,
  "municipalityId" VARCHAR(36),
  FOREIGN KEY ("crewId") REFERENCES "Crew" ("id"),
  FOREIGN KEY ("truckId") REFERENCES "Truck" ("id"),
  FOREIGN KEY ("municipalityId") REFERENCES "Municipality" ("id")
);
CREATE INDEX "DailySchedule_date_idx" ON "DailySchedule" ("date");
CREATE INDEX "DailySchedule_crewId_idx" ON "DailySchedule" ("crewId");
CREATE INDEX "DailySchedule_municipalityId_idx" ON "DailySchedule" ("municipalityId");
CREATE INDEX "DailySchedule_createdAt_idx" ON "DailySchedule" ("createdAt");

-- DailySchedule to Assignment (many-to-many)
CREATE TABLE "DailyScheduleAssignment" (
  "dailyScheduleId" VARCHAR(36) NOT NULL,
  "assignmentId" VARCHAR(36) NOT NULL,
  PRIMARY KEY ("dailyScheduleId", "assignmentId"),
  FOREIGN KEY ("dailyScheduleId") REFERENCES "DailySchedule" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("assignmentId") REFERENCES "Assignment" ("id") ON DELETE CASCADE
);

-- Forecast Table
CREATE TABLE "Forecast" (
  "id" VARCHAR(36) PRIMARY KEY,
  "startDate" TIMESTAMP NOT NULL,
  "endDate" TIMESTAMP NOT NULL,
  "weekType" "WeekType" NOT NULL,
  "materialTypes" TEXT NOT NULL,
  "driverCount" INTEGER NOT NULL,
  "loaderCount" INTEGER NOT NULL,
  "truckCount" INTEGER NOT NULL,
  "notes" TEXT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL
);
CREATE INDEX "Forecast_startDate_endDate_idx" ON "Forecast" ("startDate", "endDate");
CREATE INDEX "Forecast_weekType_idx" ON "Forecast" ("weekType");

-- Event Table
CREATE TABLE "Event" (
  "id" VARCHAR(36) PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "startDate" TIMESTAMP NOT NULL,
  "endDate" TIMESTAMP,
  "description" TEXT,
  "affectsSchedule" BOOLEAN NOT NULL DEFAULT true,
  "requiredDriversAdjust" INTEGER,
  "requiredLoadersAdjust" INTEGER,
  "requiredTrucksAdjust" INTEGER,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL
);
CREATE INDEX "Event_startDate_idx" ON "Event" ("startDate");
CREATE INDEX "Event_createdAt_idx" ON "Event" ("createdAt");

-- Attendance Table
CREATE TABLE "Attendance" (
  "id" VARCHAR(36) PRIMARY KEY,
  "userId" VARCHAR(36) NOT NULL,
  "date" TIMESTAMP NOT NULL,
  "checkInTime" TIMESTAMP,
  "checkOutTime" TIMESTAMP,
  "status" "AttendanceStatus" NOT NULL DEFAULT 'PRESENT',
  "notes" TEXT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL
);
CREATE INDEX "Attendance_userId_idx" ON "Attendance" ("userId");
CREATE INDEX "Attendance_date_idx" ON "Attendance" ("date");
CREATE INDEX "Attendance_createdAt_idx" ON "Attendance" ("createdAt");

-- ReportConfig Table
CREATE TABLE "ReportConfig" (
  "id" VARCHAR(36) PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "description" TEXT,
  "parameters" TEXT NOT NULL,
  "isTemplate" BOOLEAN NOT NULL DEFAULT false,
  "userId" VARCHAR(36),
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE SET NULL
);
CREATE INDEX "ReportConfig_name_idx" ON "ReportConfig" ("name");
CREATE INDEX "ReportConfig_userId_idx" ON "ReportConfig" ("userId");
CREATE INDEX "ReportConfig_createdAt_idx" ON "ReportConfig" ("createdAt");

-- GeneratedReport Table
CREATE TABLE "GeneratedReport" (
  "id" VARCHAR(36) PRIMARY KEY,
  "configId" VARCHAR(36),
  "parameters" TEXT NOT NULL,
  "reportData" TEXT NOT NULL,
  "userId" VARCHAR(36),
  "generatedAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY ("configId") REFERENCES "ReportConfig" ("id") ON DELETE SET NULL,
  FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE SET NULL
);
CREATE INDEX "GeneratedReport_generatedAt_idx" ON "GeneratedReport" ("generatedAt");
CREATE INDEX "GeneratedReport_userId_idx" ON "GeneratedReport" ("userId");

-- Route Table
CREATE TABLE "Route" (
  "id" VARCHAR(36) PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "description" TEXT,
  "assignmentId" VARCHAR(36),
  "truckId" VARCHAR(36),
  "waypoints" TEXT NOT NULL,
  "color" VARCHAR(255),
  "estimatedDuration" FLOAT,
  "estimatedDistance" FLOAT,
  "active" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  FOREIGN KEY ("truckId") REFERENCES "Truck" ("id") ON DELETE SET NULL
);
CREATE INDEX "Route_name_idx" ON "Route" ("name");
CREATE INDEX "Route_active_idx" ON "Route" ("active");
CREATE INDEX "Route_createdAt_idx" ON "Route" ("createdAt");

-- Geofence Table
CREATE TABLE "Geofence" (
  "id" VARCHAR(36) PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "description" TEXT,
  "type" VARCHAR(255) NOT NULL,
  "color" VARCHAR(255),
  "polygon" TEXT NOT NULL,
  "alertThreshold" FLOAT,
  "active" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL
);
CREATE INDEX "Geofence_name_idx" ON "Geofence" ("name");
CREATE INDEX "Geofence_active_idx" ON "Geofence" ("active");
CREATE INDEX "Geofence_createdAt_idx" ON "Geofence" ("createdAt");

-- TruckLocation Table
CREATE TABLE "TruckLocation" (
  "id" VARCHAR(36) PRIMARY KEY,
  "truckId" VARCHAR(36) NOT NULL,
  "routeId" VARCHAR(36),
  "position" TEXT NOT NULL,
  "heading" FLOAT,
  "speed" FLOAT,
  "timestamp" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "status" VARCHAR(255),
  FOREIGN KEY ("truckId") REFERENCES "Truck" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("routeId") REFERENCES "Route" ("id") ON DELETE SET NULL
);
CREATE INDEX "TruckLocation_truckId_idx" ON "TruckLocation" ("truckId");
CREATE INDEX "TruckLocation_routeId_idx" ON "TruckLocation" ("routeId");
CREATE INDEX "TruckLocation_timestamp_idx" ON "TruckLocation" ("timestamp");

-- RouteHistory Table
CREATE TABLE "RouteHistory" (
  "id" VARCHAR(36) PRIMARY KEY,
  "truckId" VARCHAR(36) NOT NULL,
  "routeId" VARCHAR(36) NOT NULL,
  "position" TEXT NOT NULL,
  "timestamp" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "speed" FLOAT,
  "heading" FLOAT,
  "event" VARCHAR(255),
  "eventData" TEXT,
  FOREIGN KEY ("truckId") REFERENCES "Truck" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("routeId") REFERENCES "Route" ("id") ON DELETE CASCADE
);
CREATE INDEX "RouteHistory_truckId_idx" ON "RouteHistory" ("truckId");
CREATE INDEX "RouteHistory_routeId_idx" ON "RouteHistory" ("routeId");
CREATE INDEX "RouteHistory_timestamp_idx" ON "RouteHistory" ("timestamp");

-- Dumpster Table
CREATE TABLE "Dumpster" (
  "id" VARCHAR(36) PRIMARY KEY,
  "position" TEXT NOT NULL,
  "name" VARCHAR(255) NOT NULL,
  "address" TEXT,
  "capacity" FLOAT,
  "fillLevel" FLOAT,
  "lastEmptied" TIMESTAMP,
  "municipalityId" VARCHAR(36),
  "type" VARCHAR(255),
  "notes" TEXT,
  "active" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  FOREIGN KEY ("municipalityId") REFERENCES "Municipality" ("id") ON DELETE SET NULL
);
CREATE INDEX "Dumpster_name_idx" ON "Dumpster" ("name");
CREATE INDEX "Dumpster_municipalityId_idx" ON "Dumpster" ("municipalityId");
CREATE INDEX "Dumpster_createdAt_idx" ON "Dumpster" ("createdAt");

-- WeatherAlert Table
CREATE TABLE "WeatherAlert" (
  "id" VARCHAR(36) PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "description" TEXT,
  "alertType" VARCHAR(255) NOT NULL,
  "severity" VARCHAR(255) NOT NULL,
  "thresholdValue" FLOAT NOT NULL,
  "isActive" BOOLEAN NOT NULL DEFAULT true,
  "municipalityId" VARCHAR(36),
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  FOREIGN KEY ("municipalityId") REFERENCES "Municipality" ("id") ON DELETE SET NULL
);
CREATE INDEX "WeatherAlert_name_idx" ON "WeatherAlert" ("name");
CREATE INDEX "WeatherAlert_municipalityId_idx" ON "WeatherAlert" ("municipalityId");
CREATE INDEX "WeatherAlert_createdAt_idx" ON "WeatherAlert" ("createdAt");

-- WeatherData Table
CREATE TABLE "WeatherData" (
  "id" VARCHAR(36) PRIMARY KEY,
  "municipalityId" VARCHAR(36) NOT NULL,
  "date" TIMESTAMP NOT NULL,
  "data" TEXT NOT NULL,
  "hasExtremeConditions" BOOLEAN NOT NULL DEFAULT false,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  FOREIGN KEY ("municipalityId") REFERENCES "Municipality" ("id") ON DELETE CASCADE
);
CREATE INDEX "WeatherData_municipalityId_idx" ON "WeatherData" ("municipalityId");
CREATE INDEX "WeatherData_date_idx" ON "WeatherData" ("date");

-- WeatherSource Table
CREATE TABLE "WeatherSource" (
  "id" VARCHAR(36) PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "apiKey" VARCHAR(255),
  "isActive" BOOLEAN NOT NULL DEFAULT true,
  "priority" INTEGER NOT NULL DEFAULT 1,
  "settings" TEXT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL
);
CREATE INDEX "WeatherSource_name_idx" ON "WeatherSource" ("name");
CREATE INDEX "WeatherSource_isActive_idx" ON "WeatherSource" ("isActive");
CREATE INDEX "WeatherSource_priority_idx" ON "WeatherSource" ("priority");

-- Checkpoint Table
CREATE TABLE "Checkpoint" (
  "id" VARCHAR(36) PRIMARY KEY,
  "dailyScheduleId" VARCHAR(36) NOT NULL,
  "time" TIMESTAMP NOT NULL,
  "location" TEXT NOT NULL,
  "status" VARCHAR(255) NOT NULL DEFAULT 'PENDING',
  "notes" TEXT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  FOREIGN KEY ("dailyScheduleId") REFERENCES "DailySchedule" ("id") ON DELETE CASCADE
);
CREATE INDEX "Checkpoint_dailyScheduleId_idx" ON "Checkpoint" ("dailyScheduleId");
CREATE INDEX "Checkpoint_time_idx" ON "Checkpoint" ("time");

-- Conflict Table
CREATE TABLE "Conflict" (
  "id" VARCHAR(36) PRIMARY KEY,
  "dailyScheduleId" VARCHAR(36) NOT NULL,
  "type" VARCHAR(255) NOT NULL DEFAULT 'CREW_OVERLAP',
  "conflictingEntityId" VARCHAR(36) NOT NULL,
  "description" TEXT NOT NULL,
  "resolution" VARCHAR(255) DEFAULT 'PENDING',
  "severity" VARCHAR(255) NOT NULL DEFAULT 'warning',
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  FOREIGN KEY ("dailyScheduleId") REFERENCES "DailySchedule" ("id") ON DELETE CASCADE
);
CREATE INDEX "Conflict_dailyScheduleId_idx" ON "Conflict" ("dailyScheduleId");
CREATE INDEX "Conflict_createdAt_idx" ON "Conflict" ("createdAt");

-- BlacklistedToken Table
CREATE TABLE "BlacklistedToken" (
  "id" VARCHAR(36) PRIMARY KEY,
  "token" VARCHAR(255) UNIQUE NOT NULL,
  "invalidatedAt" TIMESTAMP NOT NULL,
  "reason" VARCHAR(255) NOT NULL,
  "userId" VARCHAR(36) NOT NULL,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE
);
CREATE INDEX "BlacklistedToken_token_idx" ON "BlacklistedToken" ("token");
CREATE INDEX "BlacklistedToken_invalidatedAt_idx" ON "BlacklistedToken" ("invalidatedAt");
CREATE INDEX "BlacklistedToken_userId_idx" ON "BlacklistedToken" ("userId");

-- Notification Table
CREATE TABLE "Notification" (
  "id" VARCHAR(36) PRIMARY KEY,
  "userId" VARCHAR(36) NOT NULL,
  "type" VARCHAR(255) NOT NULL,
  "title" VARCHAR(255) NOT NULL,
  "message" TEXT NOT NULL,
  "read" BOOLEAN NOT NULL DEFAULT false,
  "metadata" JSONB,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE
);
CREATE INDEX "Notification_userId_idx" ON "Notification" ("userId");
CREATE INDEX "Notification_createdAt_idx" ON "Notification" ("createdAt");
CREATE INDEX "Notification_type_idx" ON "Notification" ("type");

-- AssignmentLocation Table
CREATE TABLE "AssignmentLocation" (
  "id" VARCHAR(36) PRIMARY KEY,
  "assignmentId" VARCHAR(36) NOT NULL,
  "latitude" FLOAT NOT NULL,
  "longitude" FLOAT NOT NULL,
  "timestamp" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX "AssignmentLocation_assignmentId_idx" ON "AssignmentLocation" ("assignmentId");
CREATE INDEX "AssignmentLocation_timestamp_idx" ON "AssignmentLocation" ("timestamp");

-- Timesheet Table
-- Timesheet Table
CREATE TABLE "Timesheet" (
  "id" VARCHAR(36) PRIMARY KEY,
  "userId" VARCHAR(36) NOT NULL,
  "crewId" VARCHAR(36),
  "startTime" TIMESTAMP NOT NULL,
  "endTime" TIMESTAMP,
  "breakTimes" JSONB,
  "routeSegments" JSONB,
  "idleTime" FLOAT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("crewId") REFERENCES "Crew" ("id") ON DELETE SET NULL
);
CREATE INDEX "Timesheet_userId_idx" ON "Timesheet" ("userId");
CREATE INDEX "Timesheet_crewId_idx" ON "Timesheet" ("crewId");
CREATE INDEX "Timesheet_startTime_idx" ON "Timesheet" ("startTime");

-- CrewPerformance Table
CREATE TABLE "CrewPerformance" (
  "id" VARCHAR(36) PRIMARY KEY,
  "crewId" VARCHAR(36) NOT NULL,
  "date" TIMESTAMP NOT NULL,
  "expectedRouteDuration" FLOAT NOT NULL,
  "actualRouteDuration" FLOAT NOT NULL,
  "deviationPercentage" FLOAT,
  "punctualityScore" FLOAT,
  "idleTime" FLOAT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  FOREIGN KEY ("crewId") REFERENCES "Crew" ("id") ON DELETE CASCADE
);
CREATE INDEX "CrewPerformance_crewId_idx" ON "CrewPerformance" ("crewId");
CREATE INDEX "CrewPerformance_date_idx" ON "CrewPerformance" ("date");

-- RouteSegment Table
CREATE TABLE "RouteSegment" (
  "id" VARCHAR(36) PRIMARY KEY,
  "routeId" VARCHAR(36) NOT NULL,
  "sequence" INTEGER NOT NULL,
  "startPoint" TEXT NOT NULL,
  "endPoint" TEXT NOT NULL,
  "duration" FLOAT NOT NULL,
  "distance" FLOAT NOT NULL,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  FOREIGN KEY ("routeId") REFERENCES "Route" ("id") ON DELETE CASCADE
);
CREATE INDEX "RouteSegment_routeId_idx" ON "RouteSegment" ("routeId");
CREATE INDEX "RouteSegment_sequence_idx" ON "RouteSegment" ("sequence");

-- DriverReportedIssue Table
CREATE TABLE "DriverReportedIssue" (
  "id" VARCHAR(36) PRIMARY KEY,
  "reportedByDriverId" VARCHAR(36),
  "reportedByDispatcherId" VARCHAR(36),
  "assignmentId" VARCHAR(36),
  "issueCategory" "IssueCategory" NOT NULL,
  "collectionType" "CollectionType",
  "residentAddress" TEXT,
  "wasteIssueType" "WasteIssueType",
  "recycleIssueType" "RecycleIssueType",
  "internalIssueType" "InternalIssueType",
  "description" TEXT,
  "reportedAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "status" "IssueStatus" NOT NULL DEFAULT 'PENDING',
  "responsibleMunicipalityId" VARCHAR(36),
  "emailSent" BOOLEAN NOT NULL DEFAULT false,
  "resolutionType" "ResolutionType",
  "resolutionNote" TEXT,
  "resolvedAt" TIMESTAMP,
  "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP NOT NULL,
  FOREIGN KEY ("reportedByDriverId") REFERENCES "Driver" ("id") ON DELETE SET NULL,
  FOREIGN KEY ("reportedByDispatcherId") REFERENCES "User" ("id") ON DELETE SET NULL,
  FOREIGN KEY ("assignmentId") REFERENCES "Assignment" ("id") ON DELETE SET NULL,
  FOREIGN KEY ("responsibleMunicipalityId") REFERENCES "Municipality" ("id") ON DELETE SET NULL
);
CREATE INDEX "DriverReportedIssue_reportedByDriverId_idx" ON "DriverReportedIssue" ("reportedByDriverId");
CREATE INDEX "DriverReportedIssue_reportedByDispatcherId_idx" ON "DriverReportedIssue" ("reportedByDispatcherId");
CREATE INDEX "DriverReportedIssue_assignmentId_idx" ON "DriverReportedIssue" ("assignmentId");
CREATE INDEX "DriverReportedIssue_issueCategory_idx" ON "DriverReportedIssue" ("issueCategory");
CREATE INDEX "DriverReportedIssue_reportedAt_idx" ON "DriverReportedIssue" ("reportedAt");

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
SELECT 'down SQL query';
-- +goose StatementEnd

-- Database schema for waste management system