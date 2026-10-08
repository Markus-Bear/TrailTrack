package com.github.markusbear.trailtrack.trail;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.assertj.MockMvcTester;

@WebMvcTest(TrailController.class)
@DisplayName("TrailController")
class TrailControllerTest {

    @Autowired
    private MockMvcTester mvc;

    @MockitoBean
    private TrailService trailService;

    @Test
    @DisplayName("GET /api/trails returns GeoJSON with the geometry as an object, not a string")
    void getTrailsReturnsGeoJsonWithGeometryAsAnObject() {
        when(trailService.getTrailSummaries()).thenReturn(TrailFeatureCollection.of(List.of(
                new TrailFeatureCollection.Feature("Feature", 7L,
                        "{\"type\":\"MultiLineString\",\"coordinates\":[[[-7.5,53.1],[-7.6,53.2]]]}",
                        new TrailFeatureCollection.Properties("Waterfall Loop", "Easy", 2.0, "blue")))));

        var response = mvc.get().uri("/api/trails").exchange();

        assertThat(response).hasStatusOk();
        assertThat(response).bodyJson().extractingPath("$.type").isEqualTo("FeatureCollection");
        assertThat(response).bodyJson().extractingPath("$.features[0].id").isEqualTo(7);
        assertThat(response).bodyJson().extractingPath("$.features[0].geometry.type")
                .isEqualTo("MultiLineString");
        assertThat(response).bodyJson().extractingPath("$.features[0].properties.name")
                .isEqualTo("Waterfall Loop");
        assertThat(response).bodyJson().extractingPath("$.features[0].properties.waymarkColour")
                .isEqualTo("blue");
    }
}
