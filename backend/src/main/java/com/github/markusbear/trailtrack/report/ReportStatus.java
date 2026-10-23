package com.github.markusbear.trailtrack.report;

/**
 * Where a report is in its life. New reports are OPEN; the other statuses
 * are set by moderation and trail maintainers.
 */
public enum ReportStatus {
    OPEN,
    CORROBORATED,
    ACKNOWLEDGED,
    RESOLVED,
    EXPIRED,
    REMOVED
}
