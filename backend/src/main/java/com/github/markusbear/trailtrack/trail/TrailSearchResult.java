package com.github.markusbear.trailtrack.trail;

import com.github.markusbear.trailtrack.report.ReportResponse;

/**
 * One trail in the search results.
 *
 * @param id the trail's id
 * @param name the trail name
 * @param difficulty Easy, Moderate or Challenging
 * @param lengthKm the length in kilometres, may be null
 * @param waymarkColour colour of the route's signs, e.g. "blue", or "unknown"
 * @param distanceKm kilometres from the searcher to the nearest point of the
 *        trail, null when searching by name only
 * @param latestReport the trail's newest report from the last 7 days, or null
 */
public record TrailSearchResult(Long id, String name, String difficulty, Double lengthKm, String waymarkColour,
                                Double distanceKm, ReportResponse latestReport) {
}
