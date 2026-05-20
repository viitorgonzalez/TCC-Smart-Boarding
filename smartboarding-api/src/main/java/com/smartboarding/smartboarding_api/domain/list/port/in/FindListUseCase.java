package com.smartboarding.smartboarding_api.domain.list.port.in;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;

import java.util.List;
import java.util.UUID;

public interface FindListUseCase {
    List<DailyList> findTodayLists();
    DailyList findById(UUID id);
    List<ListEntry> findEntriesByList(UUID listId);
}
