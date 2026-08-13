# Build multi-stage: o JDK completo e o repositorio Maven ficam no estagio de
# build e nao vao pra imagem final, que carrega so o JRE e o jar.

# ── Estagio 1: build ──────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jdk AS build

WORKDIR /build

# O wrapper e o pom entram primeiro e sozinhos: enquanto o pom nao mudar, o
# Docker reaproveita a camada de dependencias e nao rebaixa tudo a cada commit.
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x ./mvnw && ./mvnw -B --no-transfer-progress dependency:go-offline

COPY src/ src/
RUN ./mvnw -B --no-transfer-progress clean package -DskipTests

# ── Estagio 2: runtime ────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre

# Usuario sem privilegio: container que roda como root amplia qualquer escape.
RUN groupadd --system app && useradd --system --gid app --create-home app

WORKDIR /app
COPY --from=build --chown=app:app /build/target/*.jar app.jar

USER app

# Informativo (o publish real e do provedor). A porta efetiva vem de PORT.
EXPOSE 8080

ENV SPRING_PROFILES_ACTIVE=prod

# `exec` deixa o java como PID 1, entao ele recebe o SIGTERM do orquestrador e
# o shutdown graceful configurado no application.properties funciona.
ENTRYPOINT ["sh", "-c", "exec java ${JAVA_OPTS} -jar app.jar"]
