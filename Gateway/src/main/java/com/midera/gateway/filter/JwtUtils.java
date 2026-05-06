package com.midera.gateway.filter;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.spec.SecretKeySpec;
import java.security.Key;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Component
public class JwtUtils {

    @Value("${app.secret-key}")
    private String secretKey;
    /**
     * Extracts useful information from a JWT token.
     *
     * The method verifies if the token is expired and, if valid,
     * retrieves the username, userId and role stored in the token claims.
     *
     * @param token the JWT token to analyze
     * @return a map containing:
     *         - isTokenExpired : boolean indicating if the token is expired
     *         - userName : the username stored in the token (if not expired)
     *         - userId : the user identifier (if not expired)
     *         - role : the user role (if not expired)
     */
    public Map<String, Object> tokenData(String token){
        Map<String, Object> result = new HashMap<>();
        boolean isTokenExpired = extractClaims(token).getExpiration().before(new Date());
        result.put("isTokenExpired", isTokenExpired);

        if(!isTokenExpired){
            String userName = extractClaims(token).getSubject();
            String userId = extractClaims(token).get("userId", String.class);
            //String role = extractClaims(token).get("role", String.class);

            result.put("userName", userName);
            result.put("userId", userId);
            //result.put("role", role);
        }
        return result;
    }

    /**
     * Extracts the claims contained in a JWT token.
     *
     * This method validates the token signature using the secret key
     * and returns the claims payload stored inside the token.
     *
     * @param token the JWT token
     * @return the claims contained in the token
     */
    private Claims extractClaims(String token){

        // Création d'une clé de signature à partir de la clé secrète définie dans la configuration
        // Cette clé est utilisée pour vérifier l'intégrité et l'authenticité du token JWT
        Key key = new SecretKeySpec(secretKey.getBytes(), SignatureAlgorithm.HS256.getJcaName());
        return Jwts.parserBuilder()
                .setSigningKey(key)         // Définit la clé utilisée pour vérifier la signature du token
                .build()                    // Construit l'objet parser qui va analyser le token
                .parseClaimsJws(token)      // Analyse le token JWT et vérifie sa signature
                .getBody();                 // Récupère le payload du token (les données stockées dedans)
    }
}
