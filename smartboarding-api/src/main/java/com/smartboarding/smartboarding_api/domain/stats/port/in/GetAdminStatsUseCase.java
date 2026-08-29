package com.smartboarding.smartboarding_api.domain.stats.port.in;

public interface GetAdminStatsUseCase {

    /// Ocupação é a razão entre inscritos ativos de hoje e a capacidade somada
    /// dos veículos das rotas com lista aberta hoje.
    record AdminStats(long activeStudents, long routesInUse, int occupancyPercent) {}

    AdminStats execute();
}
