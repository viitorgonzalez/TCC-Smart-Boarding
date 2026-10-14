package com.smartboarding.smartboarding_api.domain.user.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
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

    @Column
    private String password;

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

    @Column(name = "institution_id")
    private UUID institutionId;

    @Column(length = 20)
    private String phone;

    @Embedded
    @Builder.Default
    private Address address = new Address();

    @Column(name = "address_legacy", columnDefinition = "TEXT")
    private String addressLegacy;

    @Column(name = "expiry_date")
    private LocalDate expiryDate;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

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

    public Address getAddress() {
        if (address == null) address = new Address();
        return address;
    }

    public boolean hasCompleteAddress() {
        return getAddress().isComplete();
    }

    public List<String> missingForList() {
        List<String> faltando = new ArrayList<>();
        if (embranco(fullName)) faltando.add("fullName");
        if (embranco(phone)) faltando.add("phone");
        if (!hasCompleteAddress()) faltando.add("address");
        if (institutionId == null) faltando.add("institution");
        return faltando;
    }

    public boolean isProfileCompleteForList() {
        return missingForList().isEmpty();
    }

    private static boolean embranco(String valor) {
        return valor == null || valor.isBlank();
    }
}
