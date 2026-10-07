package com.smartboarding.smartboarding_api.domain.user.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.*;

@Embeddable
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Address {

    @Column(name = "zip_code", length = 9)
    private String zipCode;

    @Column(length = 150)
    private String street;

    @Column(length = 100)
    private String neighborhood;

    @Column(length = 100)
    private String city;

    @Column(length = 2)
    private String state;

    @Column(name = "street_number", length = 20)
    private String streetNumber;

    @Column(length = 100)
    private String complement;

    public boolean isComplete() {
        return preenchido(zipCode) && preenchido(street)
                && preenchido(neighborhood) && preenchido(streetNumber);
    }

    public String shortForm() {
        if (!isComplete()) return "";
        String inicio = street + ", " + streetNumber;
        if (preenchido(complement)) inicio += ", " + complement;
        return inicio + " — " + neighborhood;
    }

    public String fullForm() {
        if (!isComplete()) return "";
        return shortForm() + ", " + city + "/" + state + " — " + zipCode;
    }

    private static boolean preenchido(String valor) {
        return valor != null && !valor.isBlank();
    }
}
