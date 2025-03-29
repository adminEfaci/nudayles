# ♻️ Nudayles – Municipal Waste Logistics Platform

A fullstack application for managing waste collection, driver routes, assignments, scheduling, geofencing, notifications, and real-time vehicle tracking.

## 🧱 Tech Stack

### 🔙 Backend (Go)
- Chi (REST API)
- PGX + SQLC (PostgreSQL access)
- Goose (migrations)
- Asynq (Redis-based job queue)
- Argon2 (secure password hashing)
- Zap (logging)
- PostGIS (spatial data)

### 🌐 Frontend (Next.js + React)
- Tailwind CSS + ShadCN UI
- Zustand (global state)
- React Hook Form + Zod (form validation)
- Leaflet + OpenStreetMap (mapping)

### 🐳 Docker
- PostGIS
- Redis

## 🚀 Getting Started

### 1. Clone and Configure

```bash
git clone https://github.com/adminEfaci/nudayles.git
cd nudayles
cp .env.example .env
