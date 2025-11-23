# Zerolog Logging Setup

## Overview
The backend now uses **Zerolog** for structured logging. Logs are automatically output to both **console** (with colors) and **`app.log`** file.

## Running the Backend

Simply run:
```bash
go run main.go
```

This automatically:
- Creates/appends to `app.log` file
- Outputs colored logs to terminal (stdout)
- Structures all logs as JSON with timestamps

## Log Output Examples

### Console Output (Colored)
```
8:41AM INF [SEARCH REQUEST] ip=::1 location=Surabaya query=TypeScript
8:41AM INF [SEARCH] Fetching from SerpAPI location=Surabaya query=TypeScript
8:41AM INF [API ENDPOINT] endpoint=https://serpapi.com/search?engine=google_jobs&q=TypeScript&location=Surabaya&api_key=***&google_domain=google.co.id
8:41AM INF [API RESPONSE] status_code=200
8:41AM INF [API DATA] SerpAPI returned results raw_results=0
8:41AM INF [API TRANSFORMED] transformed_jobs=0
8:41AM INF [SEARCH RESULT] Successfully retrieved jobs from SerpAPI job_count=0 location=Surabaya query=TypeScript
```

### File Output (JSON)
```json
{"level":"info","port":"8080","time":"2025-11-23T08:41:06+07:00","message":"Server starting"}
{"level":"info","time":"2025-11-23T08:41:06+07:00","message":"CORS enabled for: http://localhost:5173, http://localhost:3000, http://localhost:4173"}
{"level":"info","api_key_loaded":true,"time":"2025-11-23T08:41:06+07:00","message":"API configuration"}
{"level":"info","query":"TypeScript","location":"Surabaya","ip":"::1","time":"2025-11-23T08:41:06+07:00","message":"[SEARCH REQUEST]"}
{"level":"info","query":"TypeScript","location":"Surabaya","time":"2025-11-23T08:41:06+07:00","message":"[SEARCH] Fetching from SerpAPI"}
```

## Log Levels

- **INFO** - General information (searches, API calls, results)
- **WARN** - Warning messages (missing parameters, fallbacks)
- **ERROR** - Error conditions (failed requests, decode errors)
- **DEBUG** - Detailed job information (disabled by default, change in code to enable)
- **FATAL** - Fatal errors that stop the server

## Viewing Logs

### Real-time terminal output (while running):
```bash
go run main.go
```

### View log file after running:
```bash
cat app.log
```

### Pretty print JSON logs (requires jq):
```bash
cat app.log | jq .
```

### Tail logs in real-time:
```bash
tail -f app.log
```

### Filter logs by level:
```bash
grep '"level":"error"' app.log
```

### Filter logs by message type:
```bash
grep 'SEARCH RESULT' app.log
```

## Configuration

To adjust log level, edit `main.go` and change:
```go
zerolog.SetGlobalLevel(zerolog.InfoLevel)
```

Available levels:
- `zerolog.DebugLevel` - Most verbose
- `zerolog.InfoLevel` - (Default) General information
- `zerolog.WarnLevel` - Warnings only
- `zerolog.ErrorLevel` - Errors only
- `zerolog.FatalLevel` - Fatal only

## File Location

Logs are saved to: `backend/app.log`

The file is:
- ✅ Created automatically on first run
- ✅ Appended to on subsequent runs
- ✅ Never rotated (manual cleanup if needed)

To clear logs:
```bash
rm app.log
```

## Key Log Messages

| Message | Level | Meaning |
|---------|-------|---------|
| `[SEARCH REQUEST]` | INFO | New search API request received |
| `[SEARCH]` | INFO | Processing search (API or mock) |
| `[API ENDPOINT]` | INFO | SerpAPI call being made |
| `[API RESPONSE]` | INFO | SerpAPI response received |
| `[API DATA]` | INFO | Number of raw results from SerpAPI |
| `[API TRANSFORMED]` | INFO | Number of jobs after transformation |
| `[SEARCH RESULT]` | INFO | Final result sent to client |
| `[SEARCH ERROR]` | WARN/ERROR | Search error occurred |
| `Failed to start server` | FATAL | Server failed to start |

## Benefits of Zerolog

✅ **Structured Logging** - All data is JSON, easy to parse and analyze
✅ **Dual Output** - Console (human-readable) + File (machine-readable)
✅ **Timestamps** - All logs include precise timestamps
✅ **Low Overhead** - Minimal performance impact
✅ **Color-coded** - Terminal output is easy to scan
✅ **Fields** - Easy to add custom fields to log messages
