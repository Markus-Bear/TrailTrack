package com.github.markusbear.trailtrack.report;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST endpoint for reporting a trail's condition. Needs a login token.
 */
@RestController
public class ReportController {

    private final ReportService reportService;

    public ReportController(ReportService reportService) {
        this.reportService = reportService;
    }

    /**
     * Submits a condition report for a trail.
     *
     * @param trailId the trail the report is about
     * @param token the caller's validated login token
     * @param request the report
     * @return 201 Created with the new report, or 200 OK with the stored
     *         report if this clientRef was already submitted
     */
    @PostMapping("/api/trails/{trailId}/reports")
    public ResponseEntity<ReportResponse> submit(@PathVariable long trailId, @AuthenticationPrincipal Jwt token,
                                                 @Valid @RequestBody SubmitReportRequest request) {
        ReportService.SubmitResult result =
                reportService.submit(trailId, Long.parseLong(token.getSubject()), request);
        return ResponseEntity.status(result.created() ? HttpStatus.CREATED : HttpStatus.OK).body(result.report());
    }
}
