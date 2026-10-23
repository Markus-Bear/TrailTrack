package com.github.markusbear.trailtrack.report;

import java.time.Instant;

/**
 * A condition report as returned by the API. Does not identify the reporter.
 *
 * @param id the report's id
 * @param trailId the trail it is about
 * @param conditionType what was found
 * @param severity how bad it is, null for CLEAR
 * @param note optional extra detail
 * @param status OPEN for new reports
 * @param reportedAt when it was received
 */
public record ReportResponse(Long id, Long trailId, ConditionType conditionType, Severity severity,
                             String note, ReportStatus status, Instant reportedAt) {

    public static ReportResponse from(ConditionReport report) {
        return new ReportResponse(report.getId(), report.getTrail().getId(), report.getConditionType(),
                report.getSeverity(), report.getNote(), report.getStatus(), report.getReportedAt());
    }
}
