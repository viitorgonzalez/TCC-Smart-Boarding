package com.smartboarding.smartboarding_api.infrastructure.web.list;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.TripType;
import com.smartboarding.smartboarding_api.domain.list.port.in.AddEntryUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.in.FindListUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.in.RemoveEntryUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.list.dto.EntryRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.list.dto.EntryResponse;
import com.smartboarding.smartboarding_api.infrastructure.web.list.dto.ListResponse;
import com.smartboarding.smartboarding_api.shared.exception.UnauthorizedException;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/lists")
public class ListController {

    private final FindListUseCase findListUseCase;
    private final AddEntryUseCase addEntryUseCase;
    private final RemoveEntryUseCase removeEntryUseCase;
    private final ListEntryRepositoryPort listEntryRepository;
    private final UserRepositoryPort userRepository;

    public ListController(FindListUseCase findListUseCase,
                          AddEntryUseCase addEntryUseCase,
                          RemoveEntryUseCase removeEntryUseCase,
                          ListEntryRepositoryPort listEntryRepository,
                          UserRepositoryPort userRepository) {
        this.findListUseCase = findListUseCase;
        this.addEntryUseCase = addEntryUseCase;
        this.removeEntryUseCase = removeEntryUseCase;
        this.listEntryRepository = listEntryRepository;
        this.userRepository = userRepository;
    }

    @GetMapping("/today")
    public ResponseEntity<ApiResponse<List<ListResponse>>> getTodayLists(Authentication auth) {
        UUID userId = extractUserId(auth);
        List<ListResponse> lists = findListUseCase.findTodayLists().stream()
                .map(list -> ListResponse.from(
                        list,
                        listEntryRepository.countByDailyListIdAndIsActiveTrue(list.getId()),
                        listEntryRepository.findByUserIdAndDailyListId(userId, list.getId()).orElse(null)))
                .toList();
        return ResponseEntity.ok(ApiResponse.data(lists));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ListResponse>> findById(@PathVariable UUID id, Authentication auth) {
        UUID userId = extractUserId(auth);
        DailyList list = findListUseCase.findById(id);
        long count = listEntryRepository.countByDailyListIdAndIsActiveTrue(id);
        return ResponseEntity.ok(ApiResponse.data(ListResponse.from(
                list, count, listEntryRepository.findByUserIdAndDailyListId(userId, id).orElse(null))));
    }

    @PostMapping("/{id}/entries")
    public ResponseEntity<ApiResponse<EntryResponse>> addEntry(
            @PathVariable UUID id,
            @RequestBody(required = false) EntryRequest body,
            Authentication auth) {
        UUID userId = extractUserId(auth);
        TripType tripType = (body != null && body.tripType() != null) ? body.tripType() : TripType.ROUND_TRIP;
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.data(EntryResponse.from(addEntryUseCase.add(userId, id, tripType))));
    }

    @DeleteMapping("/{id}/entries")
    public ResponseEntity<ApiResponse<?>> removeEntry(@PathVariable UUID id, Authentication auth) {
        UUID userId = extractUserId(auth);
        removeEntryUseCase.remove(userId, id);
        return ResponseEntity.ok(ApiResponse.success());
    }

    @GetMapping("/{id}/entries")
    public ResponseEntity<ApiResponse<List<EntryResponse>>> getEntries(@PathVariable UUID id) {
        List<EntryResponse> entries = findListUseCase.findEntriesByList(id).stream()
                .map(EntryResponse::from)
                .toList();
        return ResponseEntity.ok(ApiResponse.data(entries));
    }

    private UUID extractUserId(Authentication auth) {
        String email = auth.getName();
        return userRepository.findByEmail(email)
                .map(u -> u.getId())
                .orElseThrow(() -> new UnauthorizedException("Usuário autenticado não encontrado."));
    }
}
