# Single image serving both roles. The API container and the enrichment worker
# container run the same artifact with LAKESCOUT_WORKER_ENABLED toggled, which is what
# makes `docker kill lakescout-worker` a real demonstration of lease recovery rather
# than a simulated one.

FROM --platform=$BUILDPLATFORM node:24-alpine AS frontend
WORKDIR /app
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

FROM eclipse-temurin:21-jdk-alpine AS backend
WORKDIR /app
COPY backend/.mvn/ .mvn/
COPY backend/mvnw backend/pom.xml ./
RUN ./mvnw -B --no-transfer-progress dependency:go-offline
COPY backend/src/ src/
# Static assets are served by the same Spring Boot process, so there is no separate
# web server to run or route between.
COPY --from=frontend /app/dist/ src/main/resources/static/
RUN ./mvnw -B --no-transfer-progress clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /app
RUN addgroup -S lakescout && adduser -S -G lakescout lakescout
COPY --from=backend /app/target/*.jar app.jar
USER lakescout
EXPOSE 8080
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75"
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
