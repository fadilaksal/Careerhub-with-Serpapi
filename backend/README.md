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
