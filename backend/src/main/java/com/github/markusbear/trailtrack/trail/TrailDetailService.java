package com.github.markusbear.trailtrack.trail;

import com.github.markusbear.trailtrack.report.ConditionReportRepository;
import com.github.markusbear.trailtrack.report.ConditionType;
import com.github.markusbear.trailtrack.report.ReportResponse;
import com.github.markusbear.trailtrack.report.ReportStatus;
import java.time.Duration;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.data.domain.Limit;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * A single trail with its recent condition reports.
 */
@Service
public class TrailDetailService {

    /** How far back recent reports go, until report expiry is decided. */
    static final Duration RECENT_WINDOW = Duration.ofDays(7);
    /** The most recent reports returned with a trail. */
    static final int MAX_RECENT_REPORTS = 20;

    private final TrailRepository trailRepository;
    private final ConditionReportRepository reportRepository;

    public TrailDetailService(TrailRepository trailRepository, ConditionReportRepository reportRepository) {
        this.trailRepository = trailRepository;
        this.reportRepository = reportRepository;
    }

    /**
     * @param trailId the trail's id
     * @return the trail's details, current conditions and recent reports
     * @throws TrailNotFoundException if there is no such trail
     */
    @Transactional(readOnly = true)
    public TrailDetailResponse getTrailDetail(long trailId) {
        Trail trail = trailRepository.findById(trailId).orElseThrow(() -> new TrailNotFoundException(trailId));
        List<ReportResponse> recent = reportRepository
                .findRecentForTrail(trailId, Instant.now().minus(RECENT_WINDOW), ReportStatus.REMOVED,
                        Limit.of(MAX_RECENT_REPORTS))
                .stream()
                .map(ReportResponse::from)
                .toList();

        return new TrailDetailResponse(trail.getId(), trail.getName(), trail.getDifficulty(), trail.getGrade(),
                trail.getTrailType(), trail.getLengthKm(), trail.getTimeToComplete(), trail.getDescription(),
                trail.getWebsite(),
                WaymarkColour.fromDescription(trail.getWaymarking()).name().toLowerCase(Locale.ROOT),
                currentConditions(recent), recent);
    }

    /**
     * The newest report of each condition type. A CLEAR report means the
     * trail was fine at that time, so reports older than the newest CLEAR are
     * left out.
     *
     * @param newestFirst reports, newest first
     * @return at most one report per condition type, newest first
     */
    static List<ReportResponse> currentConditions(List<ReportResponse> newestFirst) {
        Map<ConditionType, ReportResponse> latest = new LinkedHashMap<>();
        for (ReportResponse report : newestFirst) {
            latest.putIfAbsent(report.conditionType(), report);
            if (report.conditionType() == ConditionType.CLEAR) {
                break;
            }
        }
        return List.copyOf(latest.values());
    }
}
