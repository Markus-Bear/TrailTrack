package com.github.markusbear.trailtrack.trail;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Public REST endpoints for reading trails.
 */
@RestController
@RequestMapping("/api/trails")
public class TrailController {

    private final TrailService trailService;

    public TrailController(TrailService trailService) {
        this.trailService = trailService;
    }

    /**
     * Returns every trail for display on the map.
     *
     * @return a GeoJSON FeatureCollection with one feature per trail
     */
    @GetMapping
    public TrailFeatureCollection getTrails() {
        return trailService.getTrailSummaries();
    }
}
