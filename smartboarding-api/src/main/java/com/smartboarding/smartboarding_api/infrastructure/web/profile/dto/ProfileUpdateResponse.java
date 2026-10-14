package com.smartboarding.smartboarding_api.infrastructure.web.profile.dto;

import com.smartboarding.smartboarding_api.domain.profile.entity.ProfileUpdateRequest;
import com.smartboarding.smartboarding_api.domain.user.entity.User;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public record ProfileUpdateResponse(UUID id, UUID userId, String studentName,
                                    String fullName, String phone,
                                    String course, UUID institutionId, LocalDate birthDate,
                                    String zipCode, String street, String neighborhood,
                                    String city, String state, String streetNumber, String complement,
                                    String status, String rejectionReason,
                                    LocalDateTime createdAt, Current before) {

    public record Current(String fullName, String phone, String course, LocalDate birthDate,
                          String zipCode, String street, String neighborhood,
                          String city, String state, String streetNumber, String complement) {
        public static Current from(User u) {
            if (u == null) return null;
            var endereco = u.getAddress();
            return new Current(
                    u.getFullName(), u.getPhone(), u.getCourse(), u.getBirthDate(),
                    endereco == null ? null : endereco.getZipCode(),
                    endereco == null ? null : endereco.getStreet(),
                    endereco == null ? null : endereco.getNeighborhood(),
                    endereco == null ? null : endereco.getCity(),
                    endereco == null ? null : endereco.getState(),
                    endereco == null ? null : endereco.getStreetNumber(),
                    endereco == null ? null : endereco.getComplement());
        }
    }

    public static ProfileUpdateResponse from(ProfileUpdateRequest r, User student) {
        var endereco = r.getStructuredAddress();
        return new ProfileUpdateResponse(
                r.getId(), r.getUserId(), student == null ? null : student.getFullName(),
                r.getFullName(), r.getPhone(),
                r.getCourse(), r.getInstitutionId(), r.getBirthDate(),
                endereco == null ? null : endereco.getZipCode(),
                endereco == null ? null : endereco.getStreet(),
                endereco == null ? null : endereco.getNeighborhood(),
                endereco == null ? null : endereco.getCity(),
                endereco == null ? null : endereco.getState(),
                endereco == null ? null : endereco.getStreetNumber(),
                endereco == null ? null : endereco.getComplement(),
                r.getStatus().name(), r.getRejectionReason(), r.getCreatedAt(),
                Current.from(student));
    }
}
