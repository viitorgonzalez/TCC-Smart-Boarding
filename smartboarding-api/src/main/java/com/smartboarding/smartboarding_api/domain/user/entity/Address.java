package com.smartboarding.smartboarding_api.domain.user.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.*;

/// Endereço do aluno, estruturado.
///
/// Estruturado e não texto livre porque é isso que o motorista usa pra saber
/// onde a pessoa embarca: de "rua tal, perto do mercado" ninguém deriva um
/// ponto. O CEP preenche quase tudo, e sobra o número pro aluno digitar.
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

    /// Sem complemento de propósito: nem todo endereço tem um, e exigi-lo
    /// travaria quem mora em casa de rua.
    public boolean isComplete() {
        return preenchido(zipCode) && preenchido(street)
                && preenchido(neighborhood) && preenchido(streetNumber);
    }

    /// O que a carteirinha mostra. Sem CEP e sem cidade: a carteirinha se
    /// mostra pra outra pessoa, e esses dois não ajudam numa conferência
    /// presencial.
    ///
    /// Vazio quando o endereço está incompleto — meia linha numa carteirinha
    /// parece dado perdido, e quem chama decide o que colocar no lugar.
    public String shortForm() {
        if (!isComplete()) return "";
        String inicio = street + ", " + streetNumber;
        if (preenchido(complement)) inicio += ", " + complement;
        return inicio + " — " + neighborhood;
    }

    /// Ficha completa, pro admin. Aqui o CEP entra: quem administra precisa do
    /// endereço inteiro pra conferir e pra falar com o aluno.
    public String fullForm() {
        if (!isComplete()) return "";
        return shortForm() + ", " + city + "/" + state + " — " + zipCode;
    }

    private static boolean preenchido(String valor) {
        return valor != null && !valor.isBlank();
    }
}
