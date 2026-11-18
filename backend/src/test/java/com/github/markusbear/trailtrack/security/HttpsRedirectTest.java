package com.github.markusbear.trailtrack.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

import com.github.markusbear.trailtrack.trail.TrailController;
import com.github.markusbear.trailtrack.trail.TrailDetailService;
import com.github.markusbear.trailtrack.trail.TrailFeatureCollection;
import com.github.markusbear.trailtrack.trail.TrailSearchService;
import com.github.markusbear.trailtrack.trail.TrailService;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.assertj.MockMvcTester;

@WebMvcTest(controllers = TrailController.class, properties = "trailtrack.require-https=true")
@WithApiSecurity
@DisplayName("SecurityConfig with https required")
class HttpsRedirectTest {

    @Autowired
    private MockMvcTester mvc;

    @MockitoBean
    private TrailService trailService;

    @MockitoBean
    private TrailDetailService trailDetailService;

    @MockitoBean
    private TrailSearchService trailSearchService;

    @Test
    @DisplayName("a plain http request is redirected to the same address over https")
    void plainHttpIsRedirectedToHttps() {
        var response = mvc.get().uri("http://trailtrack.example/api/trails?x=1").exchange();

        assertThat(response).hasStatus3xxRedirection();
        assertThat(response).redirectedUrl().isEqualTo("https://trailtrack.example/api/trails?x=1");
    }

    @Test
    @DisplayName("an https request is answered normally")
    void httpsRequestIsAnswered() {
        when(trailService.getTrailSummaries()).thenReturn(TrailFeatureCollection.of(List.of()));

        var response = mvc.get().uri("https://trailtrack.example/api/trails").exchange();

        assertThat(response).hasStatusOk();
    }
}
