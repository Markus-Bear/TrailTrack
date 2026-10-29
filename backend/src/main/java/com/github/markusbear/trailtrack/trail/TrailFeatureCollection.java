package com.github.markusbear.trailtrack.trail;

import com.fasterxml.jackson.annotation.JsonRawValue;
import java.util.List;
import java.util.Locale;

/**
 * GeoJSON FeatureCollection of trails.
 *
 * @param type always "FeatureCollection"
 * @param features one feature per trail
 */
public record TrailFeatureCollection(String type, List<Feature> features) {

    /**
     * @param features one feature per trail
     * @return the collection
     */
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

        /**
         * @param summary the trail summary
         * @param siteKey identifies the trail's site within this response
         * @param siteName display name of the trail's site
         * @return the feature
         */
        public static Feature from(TrailSummary summary, String siteKey, String siteName) {
            List<Double> trailhead = summary.getTrailheadLon() == null ? null
                    : List.of(summary.getTrailheadLon(), summary.getTrailheadLat());
            return new Feature("Feature", summary.getId(), summary.getGeometry(), new Properties(
                    summary.getName(),
                    summary.getDifficulty(),
                    summary.getLengthKm(),
                    WaymarkColour.fromDescription(summary.getWaymarking()).name().toLowerCase(Locale.ROOT),
                    siteKey,
                    siteName,
                    trailhead));
        }
    }

    /**
     * Display attributes of a trail.
     *
     * @param name the trail name
     * @param difficulty Easy, Moderate or Challenging
     * @param lengthKm the trail length in kilometres
     * @param waymarkColour colour of the route's signs, e.g. "blue", or "unknown"
     * @param siteId identifies the trail's site; trails from one trailhead share it
     * @param siteName display name of the site, e.g. "Oughaval Woods"
     * @param trailhead the route's start point as [longitude, latitude], may be null
     */
    public record Properties(String name, String difficulty, Double lengthKm, String waymarkColour,
                             String siteId, String siteName, List<Double> trailhead) {
    }
}
