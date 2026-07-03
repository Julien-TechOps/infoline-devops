# ---- Stage 1 : build ----
# Image complète (JDK 21 + Maven) : nécessaire pour compiler, absente de l'image finale
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

# Couche stable : les dépendances ne bougent pas à chaque commit
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Couche volatile : le code source, copié après les dépendances pour préserver le cache
COPY src ./src
# -DskipTests : les tests tournent séparément en CI/CD (Phase 3), pas dans ce build local
RUN mvn package -DskipTests -B

# ---- Stage 2 : runtime ----
# JRE seul, sans JDK ni Maven ni code source : image d'exécution minimale
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Utilisateur dédié non-root, créé avant la copie pour pouvoir lui attribuer le fichier
RUN addgroup -S spring && adduser -S spring -G spring

# Seul artefact récupéré du stage 1 : le .jar déjà compilé, rien d'autre ne traverse les stages
COPY --from=build --chown=spring:spring /app/target/*.jar app.jar
USER spring

# Documente le port utilisé ; n'ouvre rien seul, le mapping réel se fait au docker run -p
EXPOSE 8080
# Process principal du conteneur : lance directement le jar, sans Maven ni script intermédiaire
ENTRYPOINT ["java", "-jar", "app.jar"]