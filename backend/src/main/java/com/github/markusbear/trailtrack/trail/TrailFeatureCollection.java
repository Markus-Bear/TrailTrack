package com.github.markusbear.trailtrack.trail;

import com.fasterxml.jackson.annotation.JsonRawValue;
import java.util.List;

/**
 * GeoJSON FeatureCollection of trails.
 *
 * @param type always "FeatureCollection"
 * @param features one feature per trail
 */
public record TrailFeatureCollection(String type, List<Feature> features) {

    public static TrailFeatureCollection of(List<Feature> features) {
        return new TrailFeatureCollection("FeatureCollection", features);
    }

    /**
     * A single trail as a GeoJSON Feature.
     *
     * @param type always "Feature"
     * @param id the trail's database id
     * @param geometry the route, as raw GeoJSON
     * @param properties the trail's display attributes
     */
    public record Feature(String type, Long id, @JsonRawValue String geometry, Properties properties) {

        public static Feature from(TrailSummary summary) {
            return new Feature("Feature", summary.getId(), summary.getGeometry(),
                    new Properties(summary.getName(), summary.getDifficulty(), summary.getLengthKm()));
        }
    }

    /**
     * Display attributes of a trail.
     *
     * @param name the trail name
     * @param difficulty Easy, Moderate or Challenging
     * @param lengthKm the trail length in kilometres
     */
    public record Properties(String name, String difficulty, Double lengthKm) {
    }
}
