package com.smartboarding.smartboarding_api.domain.shared.port.out;

public interface EmailPort {

    void send(String to, String subject, String htmlBody);
}
