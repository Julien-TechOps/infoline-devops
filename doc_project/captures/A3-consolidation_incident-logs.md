julien@Julien:~/infoline-devopskubectl logs infoline-api-78b6f764f8-kd4qq --previousus

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v4.1.0)

2026-07-15T08:06:50.858Z  INFO 1 --- [api] [           main] com.infoline.api.ApiApplication          : Starting ApiApplication v0.0.1-SNAPSHOT using Java 21.0.11 with PID 1 (/app/app.jar started by spring in /app)
2026-07-15T08:06:50.908Z  INFO 1 --- [api] [           main] com.infoline.api.ApiApplication          : No active profile set, falling back to 1 default profile: "default"
2026-07-15T08:06:53.743Z  WARN 1 --- [api] [           main] ConfigServletWebServerApplicationContext : Exception encountered during context initialization - cancelling refresh attempt: org.springframework.context.ApplicationContextException: Unable to start web server
2026-07-15T08:06:53.753Z  INFO 1 --- [api] [           main] .s.b.a.l.ConditionEvaluationReportLogger : 

Error starting ApplicationContext. To display the condition evaluation report re-run your application with 'debug' enabled.
2026-07-15T08:06:53.852Z ERROR 1 --- [api] [           main] o.s.b.d.LoggingFailureAnalysisReporter   : 

***************************
APPLICATION FAILED TO START
***************************

Description:

Failed to bind properties under 'server.port' to java.lang.Integer:

    Property: server.port
    Value: "notanumber"
    Origin: System Environment Property "SERVER_PORT"
    Reason: failed to convert java.lang.String to java.lang.Integer (caused by java.lang.NumberFormatException: For input string: "notanumber")

Action:

Update your application's configuration