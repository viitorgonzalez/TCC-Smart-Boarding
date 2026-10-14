package com.smartboarding.smartboarding_api.domain.route.port.out;

import java.util.List;
import java.util.Optional;

public interface RoutePlannerPort {

    Optional<List<Double>> legDurationsSeconds(List<GeoPoint> points);
}
