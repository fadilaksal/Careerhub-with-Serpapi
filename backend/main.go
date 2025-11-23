// main.go
package main

import (
	"fmt"
	"io"
	"net/http"
	"os"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	serpapi "github.com/serpapi/google-search-results-golang"
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
	// Initialize zerolog with multi-writer (console + file)
	logFile, err := os.OpenFile("app.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		panic(err)
	}
	defer logFile.Close()

	// Multi-writer: both console (colorful) and file
	consoleWriter := zerolog.ConsoleWriter{Out: os.Stdout}
	multiWriter := io.MultiWriter(consoleWriter, logFile)

	// Configure zerolog
	zerolog.SetGlobalLevel(zerolog.InfoLevel)
	log.Logger = zerolog.New(multiWriter).With().Timestamp().Logger()

	// Load .env file
	if err := godotenv.Load(); err != nil {
		log.Warn().Msg("No .env file found, using environment variables")
	}

	r := gin.Default()

	// CORS configuration
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"http://localhost:5173", "http://localhost:3000"},
		AllowMethods:     []string{"GET", "POST", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
	}))

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	// Jobs search endpoint
	r.GET("/api/jobs", handleJobSearch)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	apiKey := os.Getenv("SERPAPI_KEY")
	log.Info().Str("port", port).Msg("Server starting")
	log.Info().Msg("CORS enabled for: http://localhost:5173, http://localhost:3000, http://localhost:4173")
	log.Info().Bool("api_key_loaded", apiKey != "").Msg("API configuration")
	if err := r.Run(":" + port); err != nil {
		log.Fatal().Err(err).Msg("Failed to start server")
	}
}

func handleJobSearch(c *gin.Context) {
	query := c.Query("q")
	location := c.Query("location")

	log.Info().Str("query", query).Str("location", location).Str("ip", c.ClientIP()).Msg("[SEARCH REQUEST]")

	if query == "" {
		log.Warn().Msg("[SEARCH ERROR] Missing query parameter")
		c.JSON(http.StatusBadRequest, gin.H{"error": "query parameter is required"})
		return
	}

	apiKey := os.Getenv("SERPAPI_KEY")
	if apiKey == "" {
		log.Info().Str("query", query).Msg("[SEARCH] SERPAPI_KEY not set, using mock data")
		mockJobs := getMockJobs(query, location)
		log.Info().Int("job_count", len(mockJobs.Jobs)).Str("query", query).Str("location", location).Msg("[SEARCH RESULT] Returned mock jobs")
		c.JSON(http.StatusOK, mockJobs)
		return
	}

	log.Info().Str("query", query).Str("location", location).Msg("[SEARCH] Fetching from SerpAPI")
	jobs, err := fetchJobsFromSerpApi(apiKey, query, location)
	if err != nil {
		log.Error().Err(err).Msg("[SEARCH ERROR] Failed to fetch jobs")
			   c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error(), "error": "Failed"})
		return
	}

	log.Info().Int("job_count", len(jobs.Jobs)).Str("query", query).Str("location", location).Msg("[SEARCH RESULT] Successfully retrieved jobs from SerpAPI")
	c.JSON(http.StatusOK, jobs)
}

func fetchJobsFromSerpApi(apiKey, query, location string) (*JobsResponse, error) {
	// Initialize SerpAPI client
	parameter := map[string]string{
		"engine":        "google_jobs",
		"q":             query,
		"location":      location,
		"google_domain": "google.co.id",
		"gl":            "id",
		"hl":            "id",
	}

	log.Info().
		Str("query", query).
		Str("location", location).
		Msg("[API ENDPOINT] Calling SerpAPI with google_jobs engine")

	search := serpapi.NewGoogleSearch(parameter, apiKey)
	results, err := search.GetJSON()

	if err != nil {
		log.Error().Err(err).Msg("[API ERROR] Failed to make request")
		return nil, fmt.Errorf("failed to make request: %w", err)
	}

	log.Info().Msg("[API RESPONSE] Successfully received data from SerpAPI")

	// Parse jobs_results from the response
	jobsResults, ok := results["jobs_results"].([]interface{})
	if !ok {
		log.Warn().Msg("[API DATA] No jobs_results field in response")
		return &JobsResponse{Jobs: []Job{}}, nil
	}

	log.Info().Int("raw_results", len(jobsResults)).Msg("[API DATA] SerpAPI returned results")

	// Transform SerpApi response to our format
	jobs := &JobsResponse{
		Jobs: make([]Job, 0, len(jobsResults)),
	}

	for i, item := range jobsResults {
		result, ok := item.(map[string]interface{})
		if !ok {
			continue
		}

		job := Job{
			ID:       fmt.Sprintf("%d", i+1),
			Title:    getString(result, "title"),
			Company:  getString(result, "company_name"),
			Location: getString(result, "location"),
		}

		// Get description
		if desc, ok := result["description"].(string); ok {
			job.Description = desc
		}

		// Get detected extensions
		if detectedExt, ok := result["detected_extensions"].(map[string]interface{}); ok {
			if postedAt, ok := detectedExt["posted_at"].(string); ok {
				job.Posted = postedAt
			}
			if schedule, ok := detectedExt["schedule_type"].(string); ok {
				job.Type = schedule
			}
		}

		// Extract salary from extensions
		if extensions, ok := result["extensions"].([]interface{}); ok && len(extensions) > 0 {
			if ext, ok := extensions[0].(string); ok {
				job.Salary = ext
			}
		}

		// Get apply URL
		if applyOptions, ok := result["apply_options"].([]interface{}); ok && len(applyOptions) > 0 {
			if option, ok := applyOptions[0].(map[string]interface{}); ok {
				if link, ok := option["link"].(string); ok {
					job.URL = link
				}
			}
		}

		log.Debug().
			Int("job_number", i+1).
			Str("title", job.Title).
			Str("company", job.Company).
			Str("location", job.Location).
			Str("salary", job.Salary).
			Str("posted", job.Posted).
			Msg("[JOB DATA]")

		jobs.Jobs = append(jobs.Jobs, job)
	}

	log.Info().Int("transformed_jobs", len(jobs.Jobs)).Msg("[API TRANSFORMED]")
	return jobs, nil
}

// Helper function to safely get string from map
func getString(m map[string]interface{}, key string) string {
	if val, ok := m[key].(string); ok {
		return val
	}
	return ""
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

// go.mod content:
/*
module job-aggregator

go 1.21

require (
	github.com/gin-contrib/cors v1.5.0
	github.com/gin-gonic/gin v1.9.1
)
*/

// .env.example content:
/*
SERPAPI_KEY=your_serpapi_key_here
PORT=8080
*/