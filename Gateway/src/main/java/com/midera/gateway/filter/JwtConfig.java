package com.midera.gateway.filter;

import org.springframework.core.annotation.Order;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.WebFilter;
import org.springframework.web.server.WebFilterChain;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Map;

@Component
@Order(-1)
public class JwtConfig implements WebFilter {

    private final JwtUtils jwtUtils;

    public JwtConfig(JwtUtils jwtUtils){
        this.jwtUtils = jwtUtils;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
        String path = exchange.getRequest().getPath().value();
        // Routes publiques → bypass
        if (path.equals("/api/user/login") || path.equals("/api/user/register")) {
            return chain.filter(exchange);
        }

        String authHeader = exchange.getRequest()
                .getHeaders()
                .getFirst(HttpHeaders.AUTHORIZATION);

        if(authHeader != null && authHeader.startsWith("Bearer ")){
            String jwt = authHeader.substring(7);
            Map<String, Object> tokenData = jwtUtils.tokenData(jwt);

            boolean isExpired = (Boolean)tokenData.get("isTokenExpired");

            if(isExpired){
                exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
                return exchange.getResponse().setComplete();
            }

            String userName = (String) tokenData.get("userName");
            //String role = (String) tokenData.get("role");

            // Création d'un objet Authentication pour Spring Security
            Authentication authentication = new UsernamePasswordAuthenticationToken(
                    userName,
                    jwt,
                    null
            );

            // Ajoute l'utilisateur authentifié dans le contexte de sécurité réactif
            return  chain.filter(exchange)
                    .contextWrite(ReactiveSecurityContextHolder.withAuthentication(authentication));
        }

        // Pas de token → 401
        exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
        return exchange.getResponse().setComplete();
    }
}
