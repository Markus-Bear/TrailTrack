package com.github.markusbear.trailtrack.trail;

/**
 * Read-only view of a trail for map display: the fields shown on the map,
 * its site, plus the route as a simplified GeoJSON geometry string.
 */
public interface TrailSummary {

    Long getId();

    String getName();

    String getDifficulty();

    Double getLengthKm();

    /** @return the register's waymarking text, may be null */
    String getWaymarking();

    Double getTrailheadLon();

    Double getTrailheadLat();

    /** @return the id of the site the trail belongs to, null if it has no trailhead */
    Integer getSiteId();

    /** @return the route as a GeoJSON geometry, simplified for display */
    String getGeometry();
}
