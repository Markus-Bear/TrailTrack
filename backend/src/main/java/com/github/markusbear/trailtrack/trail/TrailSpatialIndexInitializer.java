package com.github.markusbear.trailtrack.trail;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Creates the spatial index that distance searches use, if it is missing.
 * Hibernate creates the tables but cannot create an index on an expression
 * such as geom::geography.
 */
@Component
public class TrailSpatialIndexInitializer implements ApplicationRunner {

    private final JdbcTemplate jdbcTemplate;

    public TrailSpatialIndexInitializer(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    /** Creates the index on startup, if it does not exist yet. */
    @Override
    public void run(ApplicationArguments args) {
        jdbcTemplate.execute(
                "CREATE INDEX IF NOT EXISTS idx_trails_geom_geography ON trails USING GIST ((geom::geography))");
    }
}
