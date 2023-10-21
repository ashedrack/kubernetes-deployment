package main

import (
	"fmt"
	"math/rand"
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

const (
	// Port on which the server runs
	serverPort = ":5000"
	// Min and Max sleep durations in milliseconds to simulate work
	minSleepDurationMs = 0
	maxSleepDurationMs = 1200
	// Error simulation rate
	errorRate = 0.15 // 15% error rate
)

var (
	// Total requests received
	requestsTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "requests_total",
		Help: "Total number of requests by status code.",
	}, []string{"code", "method"})

	// Request duration
	requestDuration = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "request_duration_seconds",
		Help:    "Duration of HTTP requests in seconds",
		Buckets: prometheus.DefBuckets, // Default buckets
	}, []string{"method"})

	// In-flight requests (concurrent requests)
	inFlightRequests = promauto.NewGauge(prometheus.GaugeOpts{
		Name: "in_flight_requests",
		Help: "Number of in-flight HTTP requests.",
	})
)

func main() {
	// Seed the random number generator
	rand.Seed(time.Now().UnixNano())

	fmt.Println("Starting server on port", serverPort)

	// Set up HTTP routes
	http.HandleFunc("/", greet)
	http.Handle("/metrics", promhttp.Handler())
	http.HandleFunc("/healthz", healthz)

	// Start the server and handle potential errors
	if err := http.ListenAndServe(serverPort, nil); err != nil {
		fmt.Println("Error starting server:", err)
	}
}

func greet(w http.ResponseWriter, r *http.Request) {
	inFlightRequests.Inc()
	defer inFlightRequests.Dec()

	start := time.Now()

	// Simulate some work
	delay := time.Duration(rand.Intn(maxSleepDurationMs-minSleepDurationMs)+minSleepDurationMs) * time.Millisecond
	time.Sleep(delay)

	// Simulate occasional errors
	if rand.Float64() < errorRate {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprint(w, "Internal Server Error")
		requestsTotal.WithLabelValues(fmt.Sprint(http.StatusInternalServerError), r.Method).Inc()
		return
	}

	w.Header().Set("Content-Type", "text/plain")
	w.WriteHeader(http.StatusOK)
	fmt.Fprint(w, "Hello Graylog, my name is Joseph")

	duration := time.Since(start).Seconds()
	requestDuration.WithLabelValues(r.Method).Observe(duration)
	requestsTotal.WithLabelValues(fmt.Sprint(http.StatusOK), r.Method).Inc()

	// Log the request and its duration
	fmt.Printf("Received %s request. Duration: %.2f seconds\n", r.Method, duration)
}

func healthz(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprint(w, "OK")
}
