package com.github.markusbear.trailtrack.trail;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Read access to trails.
 */
@Service
public class TrailService {

    /** About 5 metres at Irish latitudes: no visible change at map zoom levels. */
    static final double DISPLAY_TOLERANCE_DEGREES = 0.00005;

    private final TrailRepository trailRepository;

    public TrailService(TrailRepository trailRepository) {
        this.trailRepository = trailRepository;
    }

    /**
     * Returns every trail as a GeoJSON feature, with routes simplified for map
     * display.
     *
     * @return the trails, ordered by name
     */
    @Transactional(readOnly = true)
    public TrailFeatureCollection getTrailSummaries() {
        return TrailFeatureCollection.of(
                trailRepository.findAllSummaries(DISPLAY_TOLERANCE_DEGREES).stream()
                        .map(TrailFeatureCollection.Feature::from)
                        .toList());
    }
}
