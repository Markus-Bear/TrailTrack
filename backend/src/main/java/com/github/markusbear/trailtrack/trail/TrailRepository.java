package com.github.markusbear.trailtrack.trail;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

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

    /**
     * Returns every trail with its route simplified for map display, ordered
     * by name. Trails whose trailheads lie within siteRadius metres of each
     * other share a site id.
     *
     * @param tolerance simplification tolerance in degrees
     * @param siteRadius distance in metres within which trailheads form one site
     * @return one summary per trail
     */
    @Query(value = """
            SELECT id AS "id", name AS "name", difficulty AS "difficulty",
                   length_km AS "lengthKm", waymarking AS "waymarking",
                   ST_X(trailhead) AS "trailheadLon", ST_Y(trailhead) AS "trailheadLat",
                   ST_ClusterDBSCAN(ST_Transform(trailhead, 2157), :siteRadius, 1) OVER () AS "siteId",
                   ST_AsGeoJSON(ST_Simplify(geom, :tolerance), 6) AS "geometry"
            FROM trails
            ORDER BY name
            """, nativeQuery = true)
    List<TrailSummary> findAllSummaries(@Param("tolerance") double tolerance,
                                        @Param("siteRadius") double siteRadius);
}
