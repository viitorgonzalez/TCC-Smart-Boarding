package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.Address;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.in.UpdateAddressUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class UpdateAddressUseCaseImpl implements UpdateAddressUseCase {

    private static final int ZIP_DIGITS = 8;

    private final UserRepositoryPort userRepository;

    public UpdateAddressUseCaseImpl(UserRepositoryPort userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    @Transactional
    public Address update(UUID userId, Address pedido) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Usuário não encontrado"));

        // Guardar incompleto é de propósito: quem achou o CEP mas ainda não sabe
        // o número volta depois. Quem cobra o endereço completo é a entrada na
        // lista, num lugar só -- duplicar a regra aqui daria duas definições de
        // "completo" pra divergirem.
        Address destino = user.getAddress();
        destino.setZipCode(normalizaCep(pedido.getZipCode()));
        destino.setStreet(limpo(pedido.getStreet()));
        destino.setNeighborhood(limpo(pedido.getNeighborhood()));
        destino.setCity(limpo(pedido.getCity()));
        destino.setState(maiuscula(pedido.getState()));
        destino.setStreetNumber(limpo(pedido.getStreetNumber()));
        destino.setComplement(limpo(pedido.getComplement()));

        user.setAddress(destino);
        return userRepository.save(user).getAddress();
    }

    /// Guarda sempre no mesmo formato. O app pode mandar com ou sem hífen (o
    /// teclado numérico não tem um), e duas grafias do mesmo CEP fariam a tela
    /// mostrar diferente do que o aluno digitou da última vez.
    private static String normalizaCep(String valor) {
        String digitos = valor == null ? null : valor.replaceAll("\\D", "");
        if (digitos == null || digitos.isEmpty()) return null;
        if (digitos.length() != ZIP_DIGITS) {
            throw new BadRequestException("INVALID_ZIP_CODE",
                    "CEP precisa ter 8 dígitos.");
        }
        return digitos.substring(0, 5) + "-" + digitos.substring(5);
    }

    private static String maiuscula(String valor) {
        String limpo = limpo(valor);
        return limpo == null ? null : limpo.toUpperCase();
    }

    /// Branco vira nulo: guardar "" obrigaria isComplete() a conhecer duas
    /// formas de vazio, e uma delas escaparia.
    private static String limpo(String valor) {
        if (valor == null) return null;
        String t = valor.trim();
        return t.isEmpty() ? null : t;
    }
}
