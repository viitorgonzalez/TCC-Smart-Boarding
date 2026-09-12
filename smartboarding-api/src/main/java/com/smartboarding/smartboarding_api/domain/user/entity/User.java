package com.smartboarding.smartboarding_api.domain.user.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User implements UserDetails {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true, length = 100)
    private String email;

    /// Nulo em conta criada pelo Google que ainda nao definiu senha local.
    /// Guardar placeholder seria pior: viraria uma senha real e adivinhavel.
    @Column
    private String password;

    /// Preenchido quando a conta esta vinculada a um login do Google. A conta
    /// pode ter os dois caminhos ao mesmo tempo.
    @Column(name = "google_id", length = 64)
    private String googleId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    @Column(name = "full_name", nullable = false, length = 150)
    private String fullName;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(length = 100)
    private String course;

    // Referência, não texto: é dela que sai a rota do aluno (RN15).
    @Column(name = "institution_id")
    private UUID institutionId;

    @Column(length = 20)
    private String phone;

    @Column(columnDefinition = "TEXT")
    private String address;

    @Column(name = "expiry_date")
    private LocalDate expiryDate;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Default no builder porque o login agora recusa conta inativa: sem isto,
    // quem esquecesse de setar criaria uma conta que nunca entra, e o erro
    // apareceria como "conta desativada" num cadastro recem-feito.
    @Column(name = "is_active")
    @Builder.Default
    private boolean isActive = true;

    @Override
    public String getPassword() {
        return password;
    }

    @Override
    public @NonNull Collection<? extends GrantedAuthority> getAuthorities() {
        return Optional.ofNullable(role)
                .map(r -> new SimpleGrantedAuthority("ROLE_" + r.name()))
                .map(List::of)
                .orElse(List.of());
    }

    @Override
    public @NonNull String getUsername() {
        return email;
    }

    @Override
    public boolean isAccountNonExpired() {
        return expiryDate == null || LocalDate.now().isBefore(expiryDate);
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return isActive;
    }

    public boolean hasPassword() {
        return password != null && !password.isBlank();
    }

    public boolean hasGoogle() {
        return googleId != null && !googleId.isBlank();
    }
}
