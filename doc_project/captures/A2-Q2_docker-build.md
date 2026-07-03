julien@Julien:~/infoline-devops/api$ docker build --no-cache -t infoline-api:local .
[+] Building 44.6s (18/18) FINISHED                                                                docker:default
 => [internal] load build definition from Dockerfile                                                         0.0s
 => => transferring dockerfile: 1.28kB                                                                       0.0s
 => [internal] load metadata for docker.io/library/eclipse-temurin:21-jre-alpine                             2.8s
 => [internal] load metadata for docker.io/library/maven:3.9-eclipse-temurin-21                              2.8s
 => [auth] library/maven:pull token for registry-1.docker.io                                                 0.0s
 => [auth] library/eclipse-temurin:pull token for registry-1.docker.io                                       0.0s
 => [internal] load .dockerignore                                                                            0.0s
 => => transferring context: 73B                                                                             0.0s
 => [build 1/6] FROM docker.io/library/maven:3.9-eclipse-temurin-21@sha256:2b4496088e7b80ae10a8c9f74e574ea2  0.1s
 => => resolve docker.io/library/maven:3.9-eclipse-temurin-21@sha256:2b4496088e7b80ae10a8c9f74e574ea2138032  0.0s
 => [internal] load build context                                                                            0.0s
 => => transferring context: 847B                                                                            0.0s
 => [stage-1 1/4] FROM docker.io/library/eclipse-temurin:21-jre-alpine@sha256:3f08b13888f595cc49edabea7250b  0.0s
 => => resolve docker.io/library/eclipse-temurin:21-jre-alpine@sha256:3f08b13888f595cc49edabea7250ba69499ba  0.0s
 => CACHED [stage-1 2/4] WORKDIR /app                                                                        0.0s
 => [stage-1 3/4] RUN addgroup -S spring && adduser -S spring -G spring                                      0.4s
 => CACHED [build 2/6] WORKDIR /app                                                                          0.0s
 => [build 3/6] COPY pom.xml .                                                                               0.1s
 => [build 4/6] RUN mvn dependency:go-offline -B                                                            36.2s
 => [build 5/6] COPY src ./src                                                                               0.1s 
 => [build 6/6] RUN mvn package -DskipTests -B                                                               3.7s 
 => [stage-1 4/4] COPY --from=build --chown=spring:spring /app/target/*.jar app.jar                          0.1s 
 => exporting to image                                                                                       0.9s 
 => => exporting layers                                                                                      0.5s 
 => => exporting manifest sha256:568bfbb9ad474b8bd8462dda5aa754cc0ffb495017aac0db60ac971cb3c01d39            0.0s 
 => => exporting config sha256:d250c706b1a30affc6979e577f28bb17f9fced6b5f33f0d41e8eaeb72ccbac7c              0.0s 
 => => exporting attestation manifest sha256:fbd11158bb1ea56107a6e4f28a5446c7c8bccc0e180d345d0c3cbaadc73ff4  0.0s 
 => => exporting manifest list sha256:b30b94d33a3bb9a6a44ddfd284dc03b3736fed9e3279e26afc128ec6beabc7f9       0.0s
 => => naming to docker.io/library/infoline-api:local                                                        0.0s
 => => unpacking to docker.io/library/infoline-api:local                                                     0.1s
