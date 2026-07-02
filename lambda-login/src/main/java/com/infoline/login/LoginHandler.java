package com.infoline.login;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

/**
 * Point d'entree Lambda "login" (hello world).
 *
 * Contexte InfoLine (sujet ECF) : l'equipe technique a prevu une "java function
 * pour le login des utilisateurs/admin en serverless (ex. : aws lambda)". Cette
 * version reste un hello-world volontairement minimal : elle valide la chaine
 * Terraform -> Lambda -> API Gateway sans sur-investir dans du code applicatif
 * (la vraie logique de login sera portee par l'equipe dev).
 *
 * Signature reconnue nativement par le runtime Lambda Java (pas besoin de la
 * dependance aws-lambda-java-core pour ce cas simple) : le runtime deserialise
 * le JSON d'entree en Map et serialise la Map retournee en JSON.
 */
public class LoginHandler {

    @SuppressWarnings("unchecked")
    public Map<String, Object> handleRequest(Map<String, Object> event) {
        String method = "N/A";
        String path = "N/A";

        Object requestContextObj = event != null ? event.get("requestContext") : null;
        if (requestContextObj instanceof Map) {
            Object httpObj = ((Map<String, Object>) requestContextObj).get("http");
            if (httpObj instanceof Map) {
                Map<String, Object> http = (Map<String, Object>) httpObj;
                method = String.valueOf(http.getOrDefault("method", "N/A"));
                path = String.valueOf(http.getOrDefault("path", "N/A"));
            }
        }

        String body = String.format(
                "{\"message\":\"Hello from the InfoLine login service (serverless)\","
                        + "\"service\":\"login\",\"method\":\"%s\",\"path\":\"%s\",\"timestamp\":\"%s\"}",
                escapeJson(method), escapeJson(path), Instant.now().toString());

        Map<String, String> headers = new HashMap<>();
        headers.put("Content-Type", "application/json");

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", 200);
        response.put("headers", headers);
        response.put("body", body);
        return response;
    }

    private static String escapeJson(String value) {
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
