package com.smartboarding.smartboarding_api.infrastructure.web.warning;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.domain.warning.port.in.ManageWarningUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.warning.dto.WarningResponse;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import org.springframework.http.ResponseEntity;
import com.smartboarding.smartboarding_api.shared.exception.UnauthorizedException;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/warnings")
public class WarningController {

    private final ManageWarningUseCase manageWarningUseCase;
    private final UserRepositoryPort userRepository;

    public WarningController(ManageWarningUseCase manageWarningUseCase,
                             UserRepositoryPort userRepository) {
        this.manageWarningUseCase = manageWarningUseCase;
        this.userRepository = userRepository;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<WarningResponse>>> list(
            @RequestParam(required = false) UUID userId) {
        List<WarningResponse> items = manageWarningUseCase.list(userId).stream()
                .map(WarningResponse::from)
                .toList();
        return ResponseEntity.ok(ApiResponse.data(items));
    }

    /// O aluno só enxerga as próprias — sem parâmetro, pra não virar caminho de
    /// leitura das advertências alheias.
    @GetMapping("/me")
    public ResponseEntity<ApiResponse<List<WarningResponse>>> mine(Authentication auth) {
        User user = userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new UnauthorizedException("Usuário autenticado não encontrado."));
        List<WarningResponse> items = manageWarningUseCase.list(user.getId()).stream()
                .map(WarningResponse::from)
                .toList();
        return ResponseEntity.ok(ApiResponse.data(items));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<?>> delete(@PathVariable UUID id) {
        manageWarningUseCase.delete(id);
        return ResponseEntity.ok(ApiResponse.success());
    }
}
