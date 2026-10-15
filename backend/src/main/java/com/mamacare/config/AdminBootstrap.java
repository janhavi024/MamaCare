package com.mamacare.config;

import com.mamacare.user.AccountStatus;
import com.mamacare.user.Role;
import com.mamacare.user.User;
import com.mamacare.user.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Creates the first administrator from ADMIN_EMAIL / ADMIN_PASSWORD when no admin exists.
 * Administrators can never be created through the public registration endpoint.
 */
@Component
public class AdminBootstrap implements ApplicationRunner {
    private static final Logger log = LoggerFactory.getLogger(AdminBootstrap.class);

    private final UserRepository users;
    private final PasswordEncoder encoder;
    private final String email;
    private final String password;
    private final String name;

    public AdminBootstrap(UserRepository users, PasswordEncoder encoder,
                          @Value("${app.bootstrap.admin-email:}") String email,
                          @Value("${app.bootstrap.admin-password:}") String password,
                          @Value("${app.bootstrap.admin-name:MamaCare Admin}") String name) {
        this.users = users;
        this.encoder = encoder;
        this.email = email;
        this.password = password;
        this.name = name;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (users.existsByRole(Role.ADMIN)) return;
        if (email.isBlank() || password.length() < 8) {
            log.warn("No administrator exists. Set ADMIN_EMAIL and ADMIN_PASSWORD (min 8 chars) to create one.");
            return;
        }
        User u = new User();
        u.setFullName(name);
        u.setEmail(email.trim().toLowerCase());
        u.setPasswordHash(encoder.encode(password));
        u.setRole(Role.ADMIN);
        u.setStatus(AccountStatus.ACTIVE);
        users.save(u);
        log.info("Bootstrap administrator account created.");
    }
}
