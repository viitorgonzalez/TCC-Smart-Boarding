package com.smartboarding.smartboarding_api.domain.stop;

import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;

import java.util.Comparator;
import java.util.List;
import java.util.UUID;

public record StudentStop(Stop stop, boolean fallback) {

    public static StudentStop resolve(List<Stop> paradasDaRota, UUID institutionId) {
        List<Stop> principais = paradasDaRota.stream()
                .filter(Stop::isMainPoint)
                .sorted(Comparator.comparingInt(Stop::getSequence))
                .toList();
        if (principais.isEmpty()) return null;

        Stop dele = principais.stream()
                .filter(s -> s.getInstitutionId() != null
                        && s.getInstitutionId().equals(institutionId))
                .findFirst()
                .orElse(null);

        return dele != null
                ? new StudentStop(dele, false)
                : new StudentStop(principais.getLast(), true);
    }
}
