# Stage 1: Build
FROM maven:3.9.6-eclipse-temurin-21-alpine AS build
WORKDIR /app

# Copy the entire workspace from the context (the root)
COPY . .

RUN --mount=type=cache,target=/Users/tamil/.m2 \
    mvn dependency:go-offline -B

# Build only the specific module passed via build-arg
ARG MODULE_NAME gateway-service
RUN --mount=type=cache,target=/Users/tamil/.m2 \
    mvn clean package -pl ${MODULE_NAME} -am -DskipTests

# Stage 2: Runtime
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Use the ARG again to find the correct JAR
ARG MODULE_NAME
COPY --from=build /app/${MODULE_NAME}/target/*.jar app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]