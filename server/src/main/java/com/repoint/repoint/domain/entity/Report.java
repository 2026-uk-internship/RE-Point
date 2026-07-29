package com.repoint.domain.entity;

import com.repoint.domain.enums.ReportStatus;
import com.repoint.domain.enums.ReportType;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "reports")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Report {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "date", updatable = false)
    private LocalDateTime date;

    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    @Builder.Default
    private ReportStatus status = ReportStatus.IN_PROGRESS;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ReportType type;

    @Column(name = "related_id")
    private Long relatedId;

    @PrePersist
    protected void onCreate() {
        if (date == null) {
            date = LocalDateTime.now();
        }
    }
}
