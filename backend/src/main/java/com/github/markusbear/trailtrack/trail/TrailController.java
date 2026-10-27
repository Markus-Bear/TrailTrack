package com.github.markusbear.trailtrack.trail;

import org.springframework.web.bind.annotation.GetMapping;
import java.util.List;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Public REST endpoints for reading trails.
 */
@RestController
@RequestMapping("/api/trails")
public class TrailController {

    private final TrailService trailService;
    private final TrailDetailService trailDetailService;
    private final TrailSearchService trailSearchService;

    public TrailController(TrailService trailService, TrailDetailService trailDetailService,
                           TrailSearchService trailSearchService) {
        this.trailService = trailService;
        this.trailDetailService = trailDetailService;
        this.trailSearchService = trailSearchService;
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

    /**
     * Searches trails by name and, with a position, by distance.
     *
     * @param q text the trail name must contain, optional
     * @param lat the searcher's latitude, optional, given with lon
     * @param lon the searcher's longitude, optional, given with lat
     * @param radiusKm search radius in kilometres, 10 if not given
     * @return matching trails, nearest first with a position, otherwise A to Z
     */
    @GetMapping("/search")
    public List<TrailSearchResult> search(@RequestParam(required = false) String q,
                                          @RequestParam(required = false) Double lat,
                                          @RequestParam(required = false) Double lon,
                                          @RequestParam(required = false) Double radiusKm) {
        return trailSearchService.search(q, lat, lon, radiusKm);
    }
}
