package com.smartboarding.smartboarding_api;

import com.smartboarding.smartboarding_api.infrastructure.config.PepperedArgon2PasswordEncoder;

/**
 * Utilitário para gerar hashes Argon2id+pepper para o seed data.
 * Execute com: ./mvnw exec:java -Dexec.mainClass="com.smartboarding.smartboarding_api.SeedHashGenerator" -Dexec.classpathScope=test
 */
public class SeedHashGenerator {

    public static void main(String[] args) {
        // Mesmo pepper do application-local.properties
        String pepper = "sb_pepper_local_dev_2026_xK9#mP2@";
        PepperedArgon2PasswordEncoder encoder = new PepperedArgon2PasswordEncoder(pepper);

        String[][] users = {
                {"admin",   "sb@2026"},
                {"vitor",   "sb@2026@123"},
                {"ana",     "sb@2026"}
        };

        System.out.println("=== Hashes Argon2id+pepper para seed data ===\n");
        for (String[] u : users) {
            String hash = encoder.encode(u[1]);
            System.out.printf("-- %s (%s)\n%s\n\n", u[0], u[1], hash);
        }
    }
}
