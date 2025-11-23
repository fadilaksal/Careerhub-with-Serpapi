# Job Search Aggregator POC

Full-stack job search application using SerpApi, Go backend, and React frontend.

## Project Structure

```
job-aggregator-poc/
├── backend/          # Go + Gin backend
│   ├── main.go
│   ├── go.mod
│   └── .env
└── frontend/         # React + Vite + TanStack Query
    ├── src/
    │   ├── App.jsx
    │   ├── main.jsx
    │   └── index.css
    └── package.json
```

## Quick Start

### 1. Start Backend

```bash
cd backend
go mod download
go run main.go
```

Backend runs on http://localhost:8080

### 2. Start Frontend (in new terminal)

```bash
cd frontend
npm install
npm run dev
```

Frontend runs on http://localhost:5173

### 3. Configure (Optional)

Add your SerpApi key in `backend/.env`:
```
SERPAPI_KEY=your_key_here
```

Get free API key at https://serpapi.com

## Features

- ✅ Search jobs by keyword and location
- ✅ Real-time results from Google Jobs
- ✅ Automatic caching (5 minutes)
- ✅ Mock data fallback
- ✅ Responsive design

## Tech Stack

**Backend:**
- Go 1.21+
- Gin framework
- SerpApi integration

**Frontend:**
- React 18
- Vite
- TanStack Query
- Tailwind CSS
- Lucide Icons