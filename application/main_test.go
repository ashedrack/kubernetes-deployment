package main

import (
	"context"
	"io"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/prometheus/client_golang/prometheus/testutil"
	"github.com/stretchr/testify/assert"
)

var server *http.Server

func TestMain(m *testing.M) {
	setup()
	code := m.Run()
	teardown()
	os.Exit(code)
}

func setup() {
	// Start the server in a goroutine.
	server = &http.Server{Addr: serverPort}
	go func() {
		main()
	}()
	// Wait for the server to start.
	time.Sleep(2 * time.Second)
}

func teardown() {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	server.Shutdown(ctx)
}

func TestGreetEndpoint(t *testing.T) {
	// Make a request to the greet endpoint.
	resp, err := http.Get("http://localhost" + serverPort)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()

	// Check the response body.
	responseBody, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatal(err)
	}
	assert.Contains(t, strings.TrimSpace(string(responseBody)), "Hello Graylog, my name is Joseph")

	// Check if the metrics are updated.
	assert.GreaterOrEqual(t, testutil.ToFloat64(requestsTotal.WithLabelValues("200", "GET")), float64(1))
}

func TestMetricsEndpoint(t *testing.T) {
	// Make a request to the metrics endpoint.
	resp, err := http.Get("http://localhost" + serverPort + "/metrics")
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()

	// Check if the metrics endpoint is working.
	assert.Equal(t, http.StatusOK, resp.StatusCode)

	// Read the response body.
	metricsBody, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatal(err)
	}
	metricsOutput := string(metricsBody)

	// Check if the custom metrics are present.
	assert.Contains(t, metricsOutput, "requests_total")
	assert.Contains(t, metricsOutput, "request_duration_seconds")
	assert.Contains(t, metricsOutput, "in_flight_requests")
}

func TestHealthzEndpoint(t *testing.T) {
	// Make a request to the healthz endpoint.
	resp, err := http.Get("http://localhost" + serverPort + "/healthz")
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()

	// Check the response status.
	assert.Equal(t, http.StatusOK, resp.StatusCode)

	// Check the response body.
	responseBody, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatal(err)
	}
	assert.Equal(t, "OK", strings.TrimSpace(string(responseBody)))
}
