package com.github.markusbear.trailtrack.trail;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST endpoint for importing trail data from the Sport Ireland National
 * Trails Register.
 *
 * @todo SECURITY: this endpoint is currently open to anyone. Restrict it
 *       to the ADMIN role when Spring Security is added with user
 *       registration (Iteration 1). See
 *       docs/design/rendered/seq-07-import-trails.png.
 */
@RestController
@RequestMapping("/api/admin/trails")
public class TrailImportController {

    private final TrailImportService trailImportService;

    public TrailImportController(TrailImportService trailImportService) {
        this.trailImportService = trailImportService;
    }

    /**
     * Imports County Laois trails, creating new trails and updating
     * existing ones.
     *
     * @return the number of trails created and updated
     */
    @PostMapping("/import")
    public TrailImportService.TrailImportResult importTrails() {
        return trailImportService.importLaoisTrails();
    }
}
