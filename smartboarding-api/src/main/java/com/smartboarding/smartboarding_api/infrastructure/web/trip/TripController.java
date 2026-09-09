package com.smartboarding.smartboarding_api.infrastructure.web.trip;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.port.in.FindListUseCase;
import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;
import com.smartboarding.smartboarding_api.domain.stop.port.in.ManageStopsUseCase;
import com.smartboarding.smartboarding_api.domain.trip.entity.TripCheckpoint;
import com.smartboarding.smartboarding_api.domain.trip.port.in.ConductTripUseCase;
import com.smartboarding.smartboarding_api.domain.trip.port.out.TripCheckpointRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.trip.dto.TripStatusResponse;
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

    public TripController(ConductTripUseCase conductTripUseCase,
                          FindListUseCase findListUseCase,
                          ManageStopsUseCase manageStopsUseCase,
                          TripCheckpointRepositoryPort checkpointRepository) {
        this.conductTripUseCase = conductTripUseCase;
        this.findListUseCase = findListUseCase;
        this.manageStopsUseCase = manageStopsUseCase;
        this.checkpointRepository = checkpointRepository;
    }

    @GetMapping("/{listId}")
    public ResponseEntity<ApiResponse<TripStatusResponse>> status(@PathVariable UUID listId) {
        return ResponseEntity.ok(ApiResponse.data(statusOf(findListUseCase.findById(listId))));
    }

    @PostMapping("/{listId}/start")
    public ResponseEntity<ApiResponse<TripStatusResponse>> start(@PathVariable UUID listId) {
        return ResponseEntity.ok(ApiResponse.data(statusOf(conductTripUseCase.start(listId))));
    }

    @PostMapping("/{listId}/checkpoint/{stopId}")
    public ResponseEntity<ApiResponse<TripStatusResponse>> checkpoint(@PathVariable UUID listId,
                                                                      @PathVariable UUID stopId) {
        return ResponseEntity.ok(ApiResponse.data(statusOf(conductTripUseCase.checkpoint(listId, stopId))));
    }

    @PostMapping("/{listId}/finish")
    public ResponseEntity<ApiResponse<TripStatusResponse>> finish(@PathVariable UUID listId) {
        return ResponseEntity.ok(ApiResponse.data(statusOf(conductTripUseCase.finish(listId))));
    }

    private TripStatusResponse statusOf(DailyList list) {
        Map<UUID, TripCheckpoint> reached = checkpointRepository.findAllByDailyListId(list.getId())
                .stream()
                .collect(Collectors.toMap(TripCheckpoint::getStopId, Function.identity()));

        List<TripStatusResponse.TripStopStatus> stops = manageStopsUseCase
                .listByRoute(list.getRoute().getId()).stream()
                .filter(Stop::isMainPoint)
                .sorted(Comparator.comparingInt(Stop::getSequence))
                .map(stop -> new TripStatusResponse.TripStopStatus(
                        stop.getId(), stop.getName(), stop.getSequence(),
                        reached.containsKey(stop.getId()) ? reached.get(stop.getId()).getReachedAt() : null))
                .toList();

        return new TripStatusResponse(list.getId(), list.getRoute().getName(),
                list.getTripStartedAt(), list.getTripFinishedAt(), stops);
    }
}
