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

    /**
     * Trails whose names match a LIKE pattern, ignoring case, A to Z.
     *
     * @param pattern a LIKE pattern, with a backslash as its escape character
     * @return up to 50 matching trails
     */
    @Query(value = """
            SELECT id AS "id", name AS "name", difficulty AS "difficulty", length_km AS "lengthKm",
                   waymarking AS "waymarking", CAST(NULL AS double precision) AS "distanceMetres"
            FROM trails
            WHERE name ILIKE :pattern ESCAPE '\\'
            ORDER BY name
            LIMIT 50
            """, nativeQuery = true)
    List<TrailSearchRow> searchByName(@Param("pattern") String pattern);

    /**
     * Trails within a distance of a point whose names match a LIKE pattern,
     * nearest first. Distances are measured on the earth's surface
     * (geography), so they are in metres.
     *
     * @param lon the searcher's longitude
     * @param lat the searcher's latitude
     * @param radiusMetres how far from the point to look
     * @param pattern a LIKE pattern, with a backslash as its escape character; "%" matches every name
     * @return up to 50 trails, nearest first
     */
    @Query(value = """
            SELECT id AS "id", name AS "name", difficulty AS "difficulty", length_km AS "lengthKm",
                   waymarking AS "waymarking",
                   ST_Distance(geom::geography, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography)
                       AS "distanceMetres"
            FROM trails
            WHERE name ILIKE :pattern ESCAPE '\\'
              AND ST_DWithin(geom::geography, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography,
                             :radiusMetres)
            ORDER BY "distanceMetres", name
            LIMIT 50
            """, nativeQuery = true)
    List<TrailSearchRow> searchNear(@Param("lon") double lon, @Param("lat") double lat,
                                    @Param("radiusMetres") double radiusMetres, @Param("pattern") String pattern);
}
