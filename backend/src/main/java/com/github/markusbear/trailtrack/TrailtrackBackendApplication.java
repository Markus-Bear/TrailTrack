package com.github.markusbear.trailtrack;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Entry point of the TrailTrack backend, the REST API behind the TrailTrack
 * mobile app.
 */
@SpringBootApplication
public class TrailtrackBackendApplication {

	/**
	 * Starts the backend, listening on port 8080.
	 *
	 * @param args command-line arguments, passed on to Spring Boot
	 */
	public static void main(String[] args) {
		SpringApplication.run(TrailtrackBackendApplication.class, args);
	}

}
