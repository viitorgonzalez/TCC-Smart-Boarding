package com.smartboarding.smartboarding_api.infrastructure.config;

import com.password4j.Argon2Function;
import com.password4j.types.Argon2;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.crypto.password4j.Argon2Password4jPasswordEncoder;

/**
 * PasswordEncoder que combina Argon2id com um pepper global (segredo de servidor).
 *
 * O pepper é concatenado à senha antes do hash — mesmo que o banco vaze,
 * os hashes são inúteis sem o valor do pepper (armazenado apenas como env var).
 *
 * Parâmetros Argon2id (OWASP mínimo recomendado para autenticação web):
 *   memory = 19 MB, iterations = 2, parallelism = 1, hashLength = 32
 */
public class PepperedArgon2PasswordEncoder implements PasswordEncoder {

    private static final int MEMORY_KB   = 19456; // 19 MB
    private static final int ITERATIONS  = 2;
    private static final int PARALLELISM = 1;
    private static final int HASH_LENGTH = 32;
    private static final int SALT_LENGTH = 16;

    private final PasswordEncoder delegate;
    private final String pepper;

    public PepperedArgon2PasswordEncoder(String pepper) {
        if (pepper == null || pepper.isBlank()) {
            throw new IllegalStateException("auth.pepper não pode ser vazio");
        }
        this.pepper = pepper;
        Argon2Function argon2Function = Argon2Function.getInstance(
                MEMORY_KB, ITERATIONS, PARALLELISM, HASH_LENGTH, Argon2.ID, SALT_LENGTH
        );
        this.delegate = new Argon2Password4jPasswordEncoder(argon2Function);
    }

    @Override
    public String encode(CharSequence rawPassword) {
        return delegate.encode(withPepper(rawPassword));
    }

    @Override
    public boolean matches(CharSequence rawPassword, String encodedPassword) {
        return delegate.matches(withPepper(rawPassword), encodedPassword);
    }

    private String withPepper(CharSequence rawPassword) {
        return rawPassword + pepper;
    }
}
