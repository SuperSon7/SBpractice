# Dockerfile

# 빌드용
FROM openjdk:21-jdk-slim AS builder
WORKDIR /app
COPY . .
# TEST 건너뜀
RUN ./gradlew build -x test

# 프로덕트용
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]