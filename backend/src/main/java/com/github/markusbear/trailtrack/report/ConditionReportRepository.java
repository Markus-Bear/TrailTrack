package com.github.markusbear.trailtrack.report;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Database access for ConditionReport entities.
 */
public interface ConditionReportRepository extends JpaRepository<ConditionReport, Long> {

    /**
     * @param clientRef the reference the app created for the report
     * @return the report already stored with that reference, if any
     */
    Optional<ConditionReport> findByClientRef(UUID clientRef);
}
