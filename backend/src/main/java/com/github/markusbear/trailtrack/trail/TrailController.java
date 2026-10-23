package com.github.markusbear.trailtrack.trail;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Public REST endpoints for reading trails.
 */
@RestController
@RequestMapping("/api/trails")
public class TrailController {

    private final TrailService trailService;
    private final TrailDetailService trailDetailService;

    public TrailController(TrailService trailService, TrailDetailService trailDetailService) {
        this.trailService = trailService;
        this.trailDetailService = trailDetailService;
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

    /**
     * Returns one trail's details with its current conditions and recent
     * condition reports.
     *
     * @param id the trail's id
     * @return the trail detail, or 404 if there is no such trail
     */
    @GetMapping("/{id}")
    public TrailDetailResponse getTrail(@PathVariable long id) {
        return trailDetailService.getTrailDetail(id);
    }
}
