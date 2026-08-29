package com.smartboarding.smartboarding_api.domain.list.port.in;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/// Controle manual das listas pelo admin — o agendador cobre o dia a dia, mas
/// data extra, reabertura e correção precisam de mão humana.
public interface ManageDailyListUseCase {
    List<DailyList> findByDate(LocalDate date);
    DailyList create(UUID routeId, LocalDate date);
    /// [reason] é obrigatório: mexer na lista fora do horário muda o combinado
    /// com quem depende dela, e o aviso à rota é parte da operação.
    DailyList setStatus(UUID listId, ListStatus status, String reason);
    void delete(UUID listId);
}
