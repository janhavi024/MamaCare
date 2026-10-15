package com.mamacare.auth;

import com.mamacare.user.User;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import java.util.Optional;

@Service
public class JwtService {
    public record Parsed(Long userId, int tokenVersion) {}

    private final SecretKey key;
    private final long expirationMinutes;

    public JwtService(@Value("${app.jwt.secret:}") String secret,
                      @Value("${app.jwt.expiration-minutes}") long expirationMinutes) {
        if (secret == null || secret.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalStateException("JWT_SECRET must be set to a random value of at least 32 characters");
        }
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expirationMinutes = expirationMinutes;
    }

    public Instant expiryFromNow() {
        return Instant.now().plus(expirationMinutes, ChronoUnit.MINUTES);
    }

    /** Token carries only the user id and token version. Role and status are always re-read from the DB. */
    public String generate(User user, Instant expiresAt) {
        return Jwts.builder()
                .subject(String.valueOf(user.getId()))
                .claim("ver", user.getTokenVersion())
                .issuedAt(new Date())
                .expiration(Date.from(expiresAt))
                .signWith(key)
                .compact();
    }

    public Optional<Parsed> parse(String token) {
        try {
            var claims = Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
            Integer ver = claims.get("ver", Integer.class);
            return Optional.of(new Parsed(Long.valueOf(claims.getSubject()), ver == null ? -1 : ver));
        } catch (JwtException | IllegalArgumentException e) {
            return Optional.empty();
        }
    }
}
