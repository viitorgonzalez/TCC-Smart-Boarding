package com.smartboarding.smartboarding_api.infrastructure.web.list;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.port.in.AddEntryUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.in.FindListUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.in.RemoveEntryUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
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
    public ResponseEntity<ApiResponse<List<ListResponse>>> getTodayLists() {
        List<ListResponse> lists = findListUseCase.findTodayLists().stream()
                .map(list -> ListResponse.from(list, listEntryRepository.countByDailyListIdAndIsActiveTrue(list.getId())))
                .toList();
        return ResponseEntity.ok(ApiResponse.data(lists));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ListResponse>> findById(@PathVariable UUID id) {
        DailyList list = findListUseCase.findById(id);
        long count = listEntryRepository.countByDailyListIdAndIsActiveTrue(id);
        return ResponseEntity.ok(ApiResponse.data(ListResponse.from(list, count)));
    }

    @PostMapping("/{id}/entries")
    public ResponseEntity<ApiResponse<EntryResponse>> addEntry(@PathVariable UUID id, Authentication auth) {
        UUID userId = extractUserId(auth);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.data(EntryResponse.from(addEntryUseCase.add(userId, id))));
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
