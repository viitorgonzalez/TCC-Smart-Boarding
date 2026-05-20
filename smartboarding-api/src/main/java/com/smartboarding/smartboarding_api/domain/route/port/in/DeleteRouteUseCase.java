package com.smartboarding.smartboarding_api.domain.route.port.in;

import java.util.UUID;

public interface DeleteRouteUseCase {
    void execute(UUID id);
}
