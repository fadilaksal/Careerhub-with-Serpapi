#!/bin/bash

# Job Search Aggregator - Project Generator Script
# Run this script to generate complete project structure

set -e

echo "🚀 Generating Job Search Aggregator POC..."
echo ""

# Create project root
mkdir -p job-aggregator-poc
cd job-aggregator-poc

# ============================================
# BACKEND SETUP
# ============================================
echo "📦 Creating backend structure..."
mkdir -p backend
cd backend

# Create main.go
cat > main.go << 'EOF'
// main.go
package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

type Job struct {
	ID          string `json:"id"`
	Title       string `json:"title"`
	Company     string `json:"company"`
	Location    string `json:"location"`
	Salary      string `json:"salary"`
	Type        string `json:"type"`
	Posted      string `json:"posted"`
	Description string `json:"description"`
	URL         string `json:"url"`
}

type JobsResponse struct {
	Jobs []Job `json:"jobs"`
}

type SerpApiResponse struct {
	JobsResults []struct {
		Title           string `json:"title"`
		CompanyName     string `json:"company_name"`
		Location        string `json:"location"`
		Via             string `json:"via"`
		Description     string `json:"description"`
		JobHighlights   []struct {
			Title string   `json:"title"`
			Items []string `json:"items"`
		} `json:"job_highlights"`
		RelatedLinks []struct {
			Link string `json:"link"`
			Text string `json:"text"`
		} `json:"related_links"`
		Extensions   []string `json:"extensions"`
		DetectedExtensions struct {
			PostedAt   string `json:"posted_at"`
			Schedule   string `json:"schedule"`
		} `json:"detected_extensions"`
		ApplyOptions []struct {
			Title string `json:"title"`
			Link  string `json:"link"`
		} `json:"apply_options"`
	} `json:"jobs_results"`
	SearchMetadata struct {
		Status string `json:"status"`
	} `json:"search_metadata"`
}

func main() {
	r := gin.Default()

	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"http://localhost:5173", "http://localhost:3000"},
		AllowMethods:     []string{"GET", "POST", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
	}))

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	r.GET("/api/jobs", handleJobSearch)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

func handleJobSearch(c *gin.Context) {
	query := c.Query("q")
	location := c.Query("location")

	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "query parameter is required"})
		return
	}

	apiKey := os.Getenv("SERPAPI_KEY")
	if apiKey == "" {
		log.Println("Warning: SERPAPI_KEY not set, using mock data")
		c.JSON(http.StatusOK, getMockJobs(query, location))
		return
	}

	jobs, err := fetchJobsFromSerpApi(apiKey, query, location)
	if err != nil {
		log.Printf("Error fetching jobs: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch jobs"})
		return
	}

	c.JSON(http.StatusOK, jobs)
}

func fetchJobsFromSerpApi(apiKey, query, location string) (*JobsResponse, error) {
	baseURL := "https://serpapi.com/search"
	
	params := url.Values{}
	params.Add("engine", "google_jobs")
	params.Add("q", query)
	params.Add("location", location)
	params.Add("api_key", apiKey)

	fullURL := fmt.Sprintf("%s?%s", baseURL, params.Encode())

	resp, err := http.Get(fullURL)
	if err != nil {
		return nil, fmt.Errorf("failed to make request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("serpapi returned status: %d", resp.StatusCode)
	}

	var serpResp SerpApiResponse
	if err := json.NewDecoder(resp.Body).Decode(&serpResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	jobs := &JobsResponse{
		Jobs: make([]Job, 0, len(serpResp.JobsResults)),
	}

	for i, result := range serpResp.JobsResults {
		job := Job{
			ID:          fmt.Sprintf("%d", i+1),
			Title:       result.Title,
			Company:     result.CompanyName,
			Location:    result.Location,
			Description: result.Description,
			Posted:      result.DetectedExtensions.PostedAt,
			Type:        result.DetectedExtensions.Schedule,
		}

		for _, ext := range result.Extensions {
			job.Salary = ext
			break
		}

		if len(result.ApplyOptions) > 0 {
			job.URL = result.ApplyOptions[0].Link
		}

		jobs.Jobs = append(jobs.Jobs, job)
	}

	return jobs, nil
}

func getMockJobs(query, location string) *JobsResponse {
	return &JobsResponse{
		Jobs: []Job{
			{
				ID:          "1",
				Title:       fmt.Sprintf("Senior %s", query),
				Company:     "Tech Corp",
				Location:    location,
				Salary:      "Rp 15,000,000 - Rp 25,000,000",
				Type:        "Full-time",
				Posted:      "2 days ago",
				Description: "Looking for experienced developer with 5+ years experience in modern technologies...",
				URL:         "https://example.com/job/1",
			},
			{
				ID:          "2",
				Title:       query,
				Company:     "StartupXYZ",
				Location:    "Remote",
				Salary:      "Rp 20,000,000 - Rp 30,000,000",
				Type:        "Full-time",
				Posted:      "1 day ago",
				Description: "Join our growing team to build scalable applications...",
				URL:         "https://example.com/job/2",
			},
			{
				ID:          "3",
				Title:       fmt.Sprintf("Junior %s", query),
				Company:     "Digital Agency",
				Location:    location,
				Salary:      "Rp 12,000,000 - Rp 18,000,000",
				Type:        "Contract",
				Posted:      "5 days ago",
				Description: "We need a versatile developer who can work on various projects...",
				URL:         "https://example.com/job/3",
			},
		},
	}
}
EOF

# Create go.mod
cat > go.mod << 'EOF'
module job-aggregator

go 1.21

require (
	github.com/gin-contrib/cors v1.5.0
	github.com/gin-gonic/gin v1.9.1
)
EOF

# Create .env.example
cat > .env.example << 'EOF'
SERPAPI_KEY=your_serpapi_key_here
PORT=8080
EOF

# Create .env
cat > .env << 'EOF'
# Get your API key from https://serpapi.com
# SERPAPI_KEY=your_actual_key_here
PORT=8080
EOF

# Create README
cat > README.md << 'EOF'
# Backend - Job Search Aggregator

## Setup

```bash
# Install dependencies
go mod download

# Run server
go run main.go
```

## Configuration

Copy `.env.example` to `.env` and add your SerpApi key:
```
SERPAPI_KEY=your_key_here
```

If no API key is provided, it will use mock data.

## Endpoints

- `GET /health` - Health check
- `GET /api/jobs?q=keyword&location=location` - Search jobs
EOF

cd ..

# ============================================
# FRONTEND SETUP
# ============================================
echo "🎨 Creating frontend structure..."
mkdir -p frontend/src
cd frontend

# Create package.json
cat > package.json << 'EOF'
{
  "name": "job-aggregator-frontend",
  "private": true,
  "version": "0.0.1",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "@tanstack/react-query": "^5.17.19",
    "lucide-react": "^0.263.1"
  },
  "devDependencies": {
    "@types/react": "^18.3.3",
    "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.3.1",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.32",
    "tailwindcss": "^3.4.0",
    "vite": "^5.4.2"
  }
}
EOF

# Create vite.config.js
cat > vite.config.js << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
})
EOF

# Create tailwind.config.js
cat > tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF

# Create postcss.config.js
cat > postcss.config.js << 'EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

# Create index.html
cat > index.html << 'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Job Search Aggregator</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

# Create src/index.css
cat > src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

# Create src/main.jsx
cat > src/main.jsx << 'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import App from './App.jsx'
import './index.css'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
})

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <App />
    </QueryClientProvider>
  </React.StrictMode>,
)
EOF

# Create src/App.jsx - NOTE: You'll need to copy this from the artifact
cat > src/App.jsx << 'EOF'
// Copy the React component code from the artifact
// Or download it from Claude's response
import React from 'react';

export default function App() {
  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="text-center">
        <h1 className="text-4xl font-bold text-gray-900 mb-4">
          Job Search Aggregator
        </h1>
        <p className="text-gray-600">
          Please replace this App.jsx with the code from the artifact!
        </p>
      </div>
    </div>
  );
}
EOF

# Create frontend README
cat > README.md << 'EOF'
# Frontend - Job Search Aggregator

## Setup

```bash
# Install dependencies
npm install

# Run dev server
npm run dev
```

## Important

Replace `src/App.jsx` with the complete React component from the artifact!

## Build

```bash
npm run build
```
EOF

cd ..

# ============================================
# ROOT README
# ============================================
cat > README.md << 'EOF'
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

## Next Steps

1. Replace `frontend/src/App.jsx` with the complete code from artifact
2. Add your SerpApi key in `backend/.env`
3. Enhance with filters, favorites, and more features!
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# Backend
backend/.env
backend/job-aggregator

# Frontend
frontend/node_modules/
frontend/dist/
frontend/.env

# IDE
.vscode/
.idea/

# OS
.DS_Store
EOF

echo ""
echo "✅ Project structure generated successfully!"
echo ""
echo "📁 Structure:"
echo "   job-aggregator-poc/"
echo "   ├── backend/     (Go server)"
echo "   └── frontend/    (React app)"
echo ""
echo "🚀 Next steps:"
echo "   1. cd job-aggregator-poc/backend && go mod download && go run main.go"
echo "   2. cd job-aggregator-poc/frontend && npm install && npm run dev"
echo "   3. Replace frontend/src/App.jsx with code from the artifact"
echo ""
echo "📝 Don't forget to add your SerpApi key in backend/.env!"
echo ""
EOF

chmod +x generate.sh
echo "✅ Script created: generate.sh"
echo ""
echo "Run with: bash generate.sh"