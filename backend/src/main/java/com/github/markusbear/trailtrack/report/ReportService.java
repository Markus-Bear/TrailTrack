package com.github.markusbear.trailtrack.report;

import com.github.markusbear.trailtrack.trail.Trail;
import com.github.markusbear.trailtrack.trail.TrailNotFoundException;
import com.github.markusbear.trailtrack.trail.TrailRepository;
import com.github.markusbear.trailtrack.user.User;
import com.github.markusbear.trailtrack.user.UserRepository;
import java.time.Instant;
import java.util.Optional;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.ErrorResponseException;

/**
 * Storing condition reports.
 */
@Service
public class ReportService {

    private final ConditionReportRepository reportRepository;
    private final TrailRepository trailRepository;
    private final UserRepository userRepository;

    public ReportService(ConditionReportRepository reportRepository, TrailRepository trailRepository,
                         UserRepository userRepository) {
        this.reportRepository = reportRepository;
        this.trailRepository = trailRepository;
        this.userRepository = userRepository;
    }

    /**
     * Stores a report as OPEN. If the same user already sent a report with this
     * clientRef, that report is returned instead of storing a second copy.
     *
     * @param trailId the trail the report is about
     * @param userId the logged-in user, from their token
     * @param request the validated report
     * @return the report, and whether it was newly created
     * @throws TrailNotFoundException if there is no such trail
     * @throws ErrorResponseException 409 if another user's report already uses
     *         the clientRef, or 401 if the user's account no longer exists
     */
    @Transactional
    public SubmitResult submit(long trailId, long userId, SubmitReportRequest request) {
        Optional<ConditionReport> existing = reportRepository.findByClientRef(request.clientRef());
        if (existing.isPresent()) {
            if (!existing.get().getUser().getId().equals(userId)) {
                throw new ErrorResponseException(HttpStatus.CONFLICT);
            }
            return new SubmitResult(ReportResponse.from(existing.get()), false);
        }

        Trail trail = trailRepository.findById(trailId).orElseThrow(() -> new TrailNotFoundException(trailId));
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ErrorResponseException(HttpStatus.UNAUTHORIZED));

        ConditionReport report = new ConditionReport();
        report.setTrail(trail);
        report.setUser(user);
        report.setConditionType(request.conditionType());
        report.setSeverity(request.conditionType() == ConditionType.CLEAR ? null : request.severity());
        report.setNote(request.note() == null || request.note().isBlank() ? null : request.note().trim());
        report.setStatus(ReportStatus.OPEN);
        report.setReportedAt(Instant.now());
        report.setClientRef(request.clientRef());
        return new SubmitResult(ReportResponse.from(reportRepository.save(report)), true);
    }

    /**
     * @param report the stored report
     * @param created true if it was stored by this request, false if it was a retry
     */
    public record SubmitResult(ReportResponse report, boolean created) {
    }
}
