package com.smartboarding.smartboarding_api.infrastructure.web.trip;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.membership.port.out.RouteMemberRepositoryPort;
import com.smartboarding.smartboarding_api.domain.list.port.in.FindListUseCase;
import com.smartboarding.smartboarding_api.domain.stop.StudentStop;
import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;
import com.smartboarding.smartboarding_api.domain.stop.port.in.ManageStopsUseCase;
import com.smartboarding.smartboarding_api.domain.trip.entity.TripCheckpoint;
import com.smartboarding.smartboarding_api.domain.trip.entity.TripLeg;
import com.smartboarding.smartboarding_api.domain.trip.port.in.ConductTripUseCase;
import com.smartboarding.smartboarding_api.domain.trip.port.out.TripCheckpointRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.trip.dto.TripStatusResponse;
import com.smartboarding.smartboarding_api.shared.exception.ForbiddenException;
import com.smartboarding.smartboarding_api.shared.exception.UnauthorizedException;
import org.springframework.security.core.Authentication;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/trip")
public class TripController {

    private final ConductTripUseCase conductTripUseCase;
    private final FindListUseCase findListUseCase;
    private final ManageStopsUseCase manageStopsUseCase;
    private final TripCheckpointRepositoryPort checkpointRepository;
    private final UserRepositoryPort userRepository;
    private final RouteMemberRepositoryPort routeMemberRepository;

    public TripController(ConductTripUseCase conductTripUseCase,
                          FindListUseCase findListUseCase,
                          ManageStopsUseCase manageStopsUseCase,
                          TripCheckpointRepositoryPort checkpointRepository,
                          UserRepositoryPort userRepository,
                          RouteMemberRepositoryPort routeMemberRepository) {
        this.conductTripUseCase = conductTripUseCase;
        this.findListUseCase = findListUseCase;
        this.manageStopsUseCase = manageStopsUseCase;
        this.checkpointRepository = checkpointRepository;
        this.userRepository = userRepository;
        this.routeMemberRepository = routeMemberRepository;
    }

    /// Leitura do trajeto. O aluno acompanha por aqui.
    ///
    /// Até esta mudança o endpoint inteiro era `hasRole("ADMIN")` e não checava
    /// rota nenhuma. Agora o aluno chega -- e por isso precisa do guard: sem
    /// ele, qualquer aluno leria o trajeto de qualquer rota.
    @GetMapping("/{listId}")
    public ResponseEntity<ApiResponse<TripStatusResponse>> status(@PathVariable UUID listId,
                                                                   Authentication auth) {
        DailyList list = findListUseCase.findById(listId);
        User quem = autenticado(auth);
        assertPodeLer(quem, list);
        return ResponseEntity.ok(ApiResponse.data(statusOf(list, quem)));
    }

    @PostMapping("/{listId}/start")
    public ResponseEntity<ApiResponse<TripStatusResponse>> start(@PathVariable UUID listId) {
        return ResponseEntity.ok(ApiResponse.data(statusOf(conductTripUseCase.start(listId), null)));
    }

    @PostMapping("/{listId}/checkpoint/{stopId}")
    public ResponseEntity<ApiResponse<TripStatusResponse>> checkpoint(@PathVariable UUID listId,
                                                                      @PathVariable UUID stopId) {
        return ResponseEntity.ok(ApiResponse.data(statusOf(conductTripUseCase.checkpoint(listId, stopId), null)));
    }

    @PostMapping("/{listId}/finish")
    public ResponseEntity<ApiResponse<TripStatusResponse>> finish(@PathVariable UUID listId) {
        return ResponseEntity.ok(ApiResponse.data(statusOf(conductTripUseCase.finish(listId), null)));
    }

    private User autenticado(Authentication auth) {
        if (auth == null) throw new UnauthorizedException("Requisição sem sessão.");
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new UnauthorizedException("Usuário autenticado não encontrado."));
    }

    /// O aluno lê o trajeto da rota em que ele está, e só dela.
    private void assertPodeLer(User quem, DailyList list) {
        if (quem.getRole() == Role.ADMIN) return;
        if (!routeMemberRepository.existsByUserIdAndRouteId(
                quem.getId(), list.getRoute().getId())) {
            throw new ForbiddenException("NOT_IN_ROUTE",
                    "Você não faz parte da rota desse trajeto.");
        }
    }

    /// [quem] nulo nas ações de conduzir: quem conduz o ônibus não viaja nele,
    /// e calcular "a parada dele" ali seria inventar um destino.
    private TripStatusResponse statusOf(DailyList list, User quem) {
        TripLeg leg = list.getOutboundFinishedAt() == null ? TripLeg.OUTBOUND : TripLeg.RETURN;

        // Filtra pela perna ANTES de indexar: a mesma parada tem checkpoint nas
        // duas, e um toMap por stopId estouraria com chave duplicada assim que a
        // volta comecasse.
        Map<UUID, TripCheckpoint> reached = checkpointRepository.findAllByDailyListId(list.getId())
                .stream()
                .filter(c -> c.getLeg() == leg)
                .collect(Collectors.toMap(TripCheckpoint::getStopId, Function.identity()));

        // Na volta o onibus refaz o mesmo caminho de tras pra frente.
        Comparator<Stop> ordem = leg == TripLeg.OUTBOUND
                ? Comparator.comparingInt(Stop::getSequence)
                : Comparator.comparingInt(Stop::getSequence).reversed();

        List<TripStatusResponse.TripStopStatus> stops = manageStopsUseCase
                .listByRoute(list.getRoute().getId()).stream()
                .filter(Stop::isMainPoint)
                .sorted(ordem)
                .map(stop -> new TripStatusResponse.TripStopStatus(
                        stop.getId(), stop.getName(), stop.getSequence(),
                        reached.containsKey(stop.getId()) ? reached.get(stop.getId()).getReachedAt() : null))
                .toList();

        return new TripStatusResponse(list.getId(), list.getRoute().getName(),
                list.getTripStartedAt(), list.getOutboundFinishedAt(),
                list.getTripFinishedAt(), leg.name(), stops,
                minhaParada(list, quem, leg, reached));
    }

    /// Onde este aluno desce, e quanto falta.
    ///
    /// O tempo sai de `avg_minutes_from_start`, já calculado quando as paradas
    /// mudaram: a diferença entre a parada dele e a última alcançada. Bater no
    /// OSRM a cada consulta seria uma requisição por aluno a cada 20 segundos,
    /// num serviço com limite de uso -- e o resultado seria o mesmo número.
    private TripStatusResponse.MyStop minhaParada(DailyList list, User quem,
                                                   TripLeg leg,
                                                   Map<UUID, TripCheckpoint> reached) {
        if (quem == null || quem.getRole() != Role.STUDENT) return null;

        List<Stop> todas = manageStopsUseCase.listByRoute(list.getRoute().getId());
        // Mesma regra do card da lista, num lugar só: duas cópias mostrariam
        // dois destinos diferentes pro mesmo aluno em telas vizinhas.
        StudentStop resolvida = StudentStop.resolve(todas, quem.getInstitutionId());
        if (resolvida == null) return null;

        List<Stop> principais = todas.stream().filter(Stop::isMainPoint)
                .sorted(Comparator.comparingInt(Stop::getSequence)).toList();
        Stop dele = resolvida.stop();
        boolean alcancada = reached.containsKey(dele.getId());
        return new TripStatusResponse.MyStop(dele.getId(), dele.getName(),
                resolvida.fallback(), alcancada,
                eta(principais, dele, leg, reached, alcancada));
    }

    /// Nulo é "não sei", e a tela omite.
    ///
    /// Na volta o ônibus refaz o caminho de trás pra frente e o aluno embarca
    /// na instituição: "quanto falta até ela" não quer dizer nada ali.
    private Integer eta(List<Stop> principais, Stop dele, TripLeg leg,
                        Map<UUID, TripCheckpoint> reached, boolean alcancada) {
        if (leg != TripLeg.OUTBOUND || alcancada) return null;
        if (dele.getAvgMinutesFromStart() == null) return null;

        Stop ultima = principais.stream()
                .filter(s -> reached.containsKey(s.getId()))
                .filter(s -> s.getAvgMinutesFromStart() != null)
                .max(Comparator.comparingInt(Stop::getSequence))
                .orElse(null);
        // Trajeto sem checkpoint ainda: o tempo é o do início até a parada dele.
        int decorridos = ultima == null ? 0 : ultima.getAvgMinutesFromStart();

        int falta = dele.getAvgMinutesFromStart() - decorridos;
        // Negativo significa que o ônibus já passou sem marcar. Mostrar um
        // tempo negativo é pior que não mostrar nada.
        return falta > 0 ? falta : null;
    }
}
