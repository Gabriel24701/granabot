package config

import (
	"fmt"
	"os"
)

const defaultPort = "8080"

// Config holds runtime configuration loaded from environment variables.
type Config struct {
	Port        string
	DatabaseURL string
}

// Load reads configuration from environment variables. It fails fast if
// DATABASE_URL is not set, since the application cannot run without it.
func Load() (*Config, error) {
	port := os.Getenv("PORT")
	if port == "" {
		port = defaultPort
	}

	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		return nil, fmt.Errorf("config: DATABASE_URL environment variable is required")
	}

	return &Config{
		Port:        port,
		DatabaseURL: databaseURL,
	}, nil
}
