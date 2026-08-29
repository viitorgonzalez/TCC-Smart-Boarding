package com.smartboarding.smartboarding_api.domain.list.port.in;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;

import java.util.List;
import java.util.UUID;

public interface FindListUseCase {
    /// Aluno vê só a lista da rota derivada da sua instituição (RN15); admin vê todas.
    List<DailyList> findTodayLists(UUID requesterId);
    DailyList findById(UUID id);
    List<ListEntry> findEntriesByList(UUID listId);

    /// Dias em que o aluno esteve na lista nos últimos `months` meses.
    List<ListEntry> findMyAttendance(UUID userId, int months);
}
