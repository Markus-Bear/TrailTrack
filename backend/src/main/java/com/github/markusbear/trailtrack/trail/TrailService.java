package com.github.markusbear.trailtrack.trail;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Read access to trails.
 */
@Service
public class TrailService {

    /** About 5 metres at Irish latitudes: no visible change at map zoom levels. */
    static final double DISPLAY_TOLERANCE_DEGREES = 0.00005;

    /**
     * Trailheads closer than this form one site. Routes from one car park share
     * identical coordinates, so this only needs to allow for rounding.
     */
    static final double SITE_RADIUS_METRES = 10;

    private final TrailRepository trailRepository;

    public TrailService(TrailRepository trailRepository) {
        this.trailRepository = trailRepository;
    }

    /**
     * Returns every trail as a GeoJSON feature, with routes simplified for map
     * display and each trail tagged with the site it belongs to.
     *
     * @return the trails, ordered by name
     */
    @Transactional(readOnly = true)
    public TrailFeatureCollection getTrailSummaries() {
        List<TrailSummary> summaries =
                trailRepository.findAllSummaries(DISPLAY_TOLERANCE_DEGREES, SITE_RADIUS_METRES);

        Map<String, List<TrailSummary>> sites = new LinkedHashMap<>();
        for (TrailSummary s : summaries) {
            sites.computeIfAbsent(siteKey(s), k -> new ArrayList<>()).add(s);
        }
        Map<String, String> siteNames = new LinkedHashMap<>();
        sites.forEach((key, trails) ->
                siteNames.put(key, siteName(trails.stream().map(TrailSummary::getName).toList())));

        return TrailFeatureCollection.of(summaries.stream()
                .map(s -> TrailFeatureCollection.Feature.from(s, siteKey(s), siteNames.get(siteKey(s))))
                .toList());
    }

    /**
     * A trail with no trailhead is not clustered, so it forms a site of its own.
     */
    private static String siteKey(TrailSummary summary) {
        return summary.getSiteId() != null ? "site-" + summary.getSiteId() : "trail-" + summary.getId();
    }

    /**
     * Names a site after the words its trails' names start with, e.g.
     * "Oughaval Woods - Mass Rock Walk" and "Oughaval Woods - Beech Way Walk"
     * give "Oughaval Woods". A site with one trail takes the trail's name.
     *
     * @param names the names of the trails at the site
     * @return the site name
     */
    static String siteName(List<String> names) {
        if (names.size() == 1) {
            return names.get(0);
        }
        List<String[]> words = names.stream().map(n -> n.trim().split("\\s+")).toList();
        int common = 0;
        outer:
        while (true) {
            for (String[] w : words) {
                if (common >= w.length || !w[common].equals(words.get(0)[common])) {
                    break outer;
                }
            }
            common++;
        }
        String prefix = String.join(" ", Arrays.copyOf(words.get(0), common))
                .replaceAll("[\\s\\-]+$", "");
        return prefix.isEmpty() ? names.get(0) : prefix;
    }
}
