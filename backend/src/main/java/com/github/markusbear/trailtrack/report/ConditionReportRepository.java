package com.github.markusbear.trailtrack.report;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Limit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Database access for ConditionReport entities.
 */
public interface ConditionReportRepository extends JpaRepository<ConditionReport, Long> {

    /**
     * @param clientRef the reference the app created for the report
     * @return the report already stored with that reference, if any
     */
    Optional<ConditionReport> findByClientRef(UUID clientRef);

    /**
     * @param trailId the trail
     * @param since only reports received at or after this time
     * @param hidden a status whose reports are left out, e.g. REMOVED
     * @param limit the most reports to return
     * @return the trail's reports, newest first
     */
    @Query("""
            SELECT r FROM ConditionReport r
            WHERE r.trail.id = :trailId AND r.reportedAt >= :since AND r.status <> :hidden
            ORDER BY r.reportedAt DESC
            """)
    List<ConditionReport> findRecentForTrail(@Param("trailId") long trailId, @Param("since") Instant since,
                                             @Param("hidden") ReportStatus hidden, Limit limit);

    /**
     * @param trailIds the trails, must not be empty
     * @param since only reports received at or after this time
     * @param hidden a status whose reports are left out, e.g. REMOVED
     * @return the trails' reports, newest first
     */
    @Query("""
            SELECT r FROM ConditionReport r
            WHERE r.trail.id IN :trailIds AND r.reportedAt >= :since AND r.status <> :hidden
            ORDER BY r.reportedAt DESC
            """)
    List<ConditionReport> findRecentForTrails(@Param("trailIds") Collection<Long> trailIds,
                                              @Param("since") Instant since, @Param("hidden") ReportStatus hidden);
}
