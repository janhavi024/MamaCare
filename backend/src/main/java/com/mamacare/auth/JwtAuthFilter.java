package com.mamacare.auth;

import com.mamacare.common.AuthUser;
import com.mamacare.user.AccountStatus;
import com.mamacare.user.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Component
public class JwtAuthFilter extends OncePerRequestFilter {
    private final JwtService jwt;
    private final UserRepository users;

    public JwtAuthFilter(JwtService jwt, UserRepository users) {
        this.jwt = jwt;
        this.users = users;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {
        String header = req.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            jwt.parse(header.substring(7)).flatMap(p -> users.findById(p.userId())
                            .filter(u -> u.getTokenVersion() == p.tokenVersion())
                            .filter(u -> u.getStatus() != AccountStatus.SUSPENDED))
                    .ifPresent(u -> {
                        // ACTIVE accounts get their real role; PENDING/REJECTED accounts get a role that matches
                        // no business endpoint, so they can only reach /api/auth/**.
                        String authority = u.getStatus() == AccountStatus.ACTIVE ? "ROLE_" + u.getRole().name() : "ROLE_PENDING";
                        var principal = new AuthUser(u.getId(), u.getEmail(), u.getRole(), u.getStatus());
                        var auth = new UsernamePasswordAuthenticationToken(principal, null, List.of(new SimpleGrantedAuthority(authority)));
                        SecurityContextHolder.getContext().setAuthentication(auth);
                    });
        }
        chain.doFilter(req, res);
    }
}
