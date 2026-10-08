package com.github.markusbear.trailtrack.trail;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

@DisplayName("WaymarkColour")
class WaymarkColourTest {

    @ParameterizedTest(name = "{0} is {1}")
    @CsvSource({
            "Blue arrow on white background, BLUE",
            "Purple arrow on white background, PURPLE",
            "White arrow on green background, GREEN",
            "white arrow on red background, RED",
            "Yellow arrow on black background, YELLOW",
    })
    @DisplayName("takes the arrow colour, or the background when the arrow is white")
    void parsesTheRegistersWaymarkingText(String description, WaymarkColour expected) {
        assertThat(WaymarkColour.fromDescription(description)).isEqualTo(expected);
    }

    @Test
    @DisplayName("is UNKNOWN when the text is missing or not recognised")
    void returnsUnknownWhenMissingOrUnrecognised() {
        assertThat(WaymarkColour.fromDescription(null)).isEqualTo(WaymarkColour.UNKNOWN);
        assertThat(WaymarkColour.fromDescription("Follow the posts")).isEqualTo(WaymarkColour.UNKNOWN);
        assertThat(WaymarkColour.fromDescription("Teal arrow on white background")).isEqualTo(WaymarkColour.UNKNOWN);
    }
}
