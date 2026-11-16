package com.github.markusbear.trailtrack;

import static org.assertj.core.api.Assertions.assertThat;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

@SpringBootTest
@DisplayName("Database migrations")
class DatabaseMigrationTest {

    @Autowired
    private Flyway flyway;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    @DisplayName("every migration has been applied")
    void everyMigrationIsApplied() {
        assertThat(flyway.info().current()).isNotNull();
        assertThat(flyway.info().pending()).isEmpty();
    }

    @Test
    @DisplayName("the trails table has the spatial index that distance searches use")
    void trailsHaveTheSpatialIndex() {
        Integer indexes = jdbcTemplate.queryForObject(
                "SELECT count(*) FROM pg_indexes WHERE tablename = 'trails' AND indexname = 'idx_trails_geom_geography'",
                Integer.class);

        assertThat(indexes).isEqualTo(1);
    }
}
