package com.github.markusbear.trailtrack.trail;

import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * The colour that identifies a route on its trail signs, derived from the
 * register's waymarking text.
 */
public enum WaymarkColour {
    GREEN, BLUE, RED, PURPLE, YELLOW, ORANGE, UNKNOWN;

    private static final Pattern WAYMARK =
            Pattern.compile("(\\w+)\\s+arrows?\\s+on\\s+(?:a\\s+)?(\\w+)\\s+background", Pattern.CASE_INSENSITIVE);

    /**
     * Parses waymarking text such as "Blue arrow on white background" or
     * "White arrow on red background".
     *
     * The route's colour is the arrow colour, unless the arrow is white, in
     * which case the background carries the colour. National Waymarked Ways
     * use a yellow arrow on black, which parses as yellow.
     *
     * @param description the register's waymarking text, may be null
     * @return the route colour, or UNKNOWN if it cannot be determined
     */
    public static WaymarkColour fromDescription(String description) {
        if (description == null) {
            return UNKNOWN;
        }
        Matcher m = WAYMARK.matcher(description);
        if (!m.find()) {
            return UNKNOWN;
        }
        String arrow = m.group(1).toLowerCase(Locale.ROOT);
        return parse(arrow.equals("white") ? m.group(2) : arrow);
    }

    private static WaymarkColour parse(String colour) {
        try {
            return valueOf(colour.toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            return UNKNOWN;
        }
    }
}
