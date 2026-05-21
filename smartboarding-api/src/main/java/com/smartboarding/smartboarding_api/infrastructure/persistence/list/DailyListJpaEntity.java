package com.smartboarding.smartboarding_api.infrastructure.persistence.list;

import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;
import com.smartboarding.smartboarding_api.infrastructure.persistence.route.RouteJpaEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "daily_lists", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"route_id", "date"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyListJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "route_id", nullable = false)
    private UUID routeId;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "route_id", insertable = false, updatable = false)
    private RouteJpaEntity route;

    @Column(nullable = false)
    private LocalDate date;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private ListStatus status;

    @Column(name = "closed_at")
    private LocalDateTime closedAt;
}
