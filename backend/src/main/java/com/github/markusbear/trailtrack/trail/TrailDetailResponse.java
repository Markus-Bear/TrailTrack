package com.github.markusbear.trailtrack.trail;

import com.github.markusbear.trailtrack.report.ReportResponse;
import java.util.List;

/**
 * Everything shown on a trail's detail page.
 *
 * @param id the trail's id
 * @param name the trail name
 * @param difficulty Easy, Moderate or Challenging
 * @param grade the register's grade, may be null
 * @param trailType e.g. "Looped Walk", may be null
 * @param lengthKm the length in kilometres, may be null
 * @param timeToComplete e.g. "1 hour", may be null
 * @param description the register's description, may be null
 * @param website a page about the trail, may be null
 * @param waymarkColour colour of the route's signs, e.g. "blue", or "unknown"
 * @param currentConditions the newest report of each condition type, newest first
 * @param recentReports reports from the last 7 days, newest first
 */
public record TrailDetailResponse(Long id, String name, String difficulty, String grade, String trailType,
                                  Double lengthKm, String timeToComplete, String description, String website,
                                  String waymarkColour, List<ReportResponse> currentConditions,
                                  List<ReportResponse> recentReports) {
}
