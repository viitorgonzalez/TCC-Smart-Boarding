package com.smartboarding.smartboarding_api.domain.list.entity;

import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyList {
    private UUID id;
    private Route route;
    private LocalDate date;
    private ListStatus status;
    private LocalDateTime closedAt;
}
