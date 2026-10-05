package com.github.markusbear.trailtrack.trail;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Database access for Trail entities.
 */
public interface TrailRepository extends JpaRepository<Trail, Long> {

    /**
     * Finds the trail with the given Sport Ireland TrailID.
     *
     * @param sourceTrailId the register's TrailID
     * @return the matching trail, or empty if it has not been imported yet
     */
    Optional<Trail> findBySourceTrailId(Integer sourceTrailId);
}
