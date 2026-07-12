package com.smartboarding.smartboarding_api.infrastructure.web.list.dto;

import com.smartboarding.smartboarding_api.domain.list.entity.TripType;

/** Corpo opcional do POST /api/lists/{id}/entries. tripType padrão = ROUND_TRIP. */
public record EntryRequest(TripType tripType) {}
