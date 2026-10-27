package com.github.markusbear.trailtrack.trail;

/**
 * One row of a trail search: the fields shown in the results list.
 */
public interface TrailSearchRow {

    Long getId();

    String getName();

    String getDifficulty();

    Double getLengthKm();

    String getWaymarking();

    /** @return metres from the searcher's position to the nearest point of the trail, null for name-only searches */
    Double getDistanceMetres();
}
