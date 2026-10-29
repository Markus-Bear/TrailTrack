package com.github.markusbear.trailtrack.trail;

import com.github.markusbear.trailtrack.report.ConditionReport;
import com.github.markusbear.trailtrack.report.ConditionReportRepository;
import com.github.markusbear.trailtrack.report.ReportResponse;
import com.github.markusbear.trailtrack.report.ReportStatus;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

/**
 * Searching trails by name and by distance from a position.
 */
@Service
public class TrailSearchService {

    /** The radius used when a position is given without one. */
    static final double DEFAULT_RADIUS_KM = 10;

    /** The largest radius allowed, so a search cannot cover the whole country. */
    static final double MAX_RADIUS_KM = 100;

    private final TrailRepository trailRepository;
    private final ConditionReportRepository reportRepository;

    public TrailSearchService(TrailRepository trailRepository, ConditionReportRepository reportRepository) {
        this.trailRepository = trailRepository;
        this.reportRepository = reportRepository;
    }

    /**
     * Finds trails whose names contain {@code q}, ignoring case, and, if a
     * position is given, that lie within {@code radiusKm} of it. Results are
     * nearest first with a position, otherwise A to Z. The position is only
     * used for this search and never stored.
     *
     * @param q text the name must contain, or null or blank for any name
     * @param lat the searcher's latitude, given together with lon, or null
     * @param lon the searcher's longitude, given together with lat, or null
     * @param radiusKm search radius, 10 km if not given
     * @return up to 50 trails with their latest condition
     * @throws ResponseStatusException 400 if only one of lat and lon is given,
     *         either is out of range, or the radius is not between 0 and 100 km
     */
    @Transactional(readOnly = true)
    public List<TrailSearchResult> search(String q, Double lat, Double lon, Double radiusKm) {
        if ((lat == null) != (lon == null)) {
            throw badRequest("lat and lon must be given together");
        }
        if (lat != null && (lat < -90 || lat > 90 || lon < -180 || lon > 180)) {
            throw badRequest("lat must be between -90 and 90, and lon between -180 and 180");
        }
        double radius = radiusKm == null ? DEFAULT_RADIUS_KM : radiusKm;
        if (radius <= 0 || radius > MAX_RADIUS_KM) {
            throw badRequest("radiusKm must be more than 0 and at most " + (int) MAX_RADIUS_KM);
        }

        String pattern = likePattern(q);
        List<TrailSearchRow> rows = lat == null
                ? trailRepository.searchByName(pattern)
                : trailRepository.searchNear(lon, lat, radius * 1000, pattern);
        Map<Long, ReportResponse> latest = latestReports(rows);

        return rows.stream()
                .map(row -> new TrailSearchResult(row.getId(), row.getName(), row.getDifficulty(),
                        row.getLengthKm(),
                        WaymarkColour.fromDescription(row.getWaymarking()).name().toLowerCase(Locale.ROOT),
                        row.getDistanceMetres() == null ? null : row.getDistanceMetres() / 1000,
                        latest.get(row.getId())))
                .toList();
    }

    /**
     * Turns search text into a LIKE pattern that matches it anywhere in a
     * name. Characters that LIKE treats specially are escaped, so they only
     * match themselves.
     *
     * @param q the search text, may be null
     * @return the pattern, or "%" to match every name
     */
    static String likePattern(String q) {
        if (q == null || q.isBlank()) {
            return "%";
        }
        String escaped = q.trim()
                .replace("\\", "\\\\")
                .replace("%", "\\%")
                .replace("_", "\\_");
        return "%" + escaped + "%";
    }

    private Map<Long, ReportResponse> latestReports(List<TrailSearchRow> rows) {
        Map<Long, ReportResponse> latest = new HashMap<>();
        if (rows.isEmpty()) {
            return latest;
        }
        List<Long> ids = rows.stream().map(TrailSearchRow::getId).toList();
        Instant since = Instant.now().minus(TrailDetailService.RECENT_WINDOW);
        for (ConditionReport report : reportRepository.findRecentForTrails(ids, since, ReportStatus.REMOVED)) {
            latest.putIfAbsent(report.getTrail().getId(), ReportResponse.from(report));
        }
        return latest;
    }

    private static ResponseStatusException badRequest(String reason) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, reason);
    }
}
