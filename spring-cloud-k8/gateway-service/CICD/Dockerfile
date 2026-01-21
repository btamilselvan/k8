FROM eclipse-temurin:21-jre-alpine

ENV profile dev

# Add the application's jar to the container
ADD target/gateway-service.jar /app/gateway-service.jar

WORKDIR /app

# Run the jar file 
ENTRYPOINT ["java", "-jar", "-Dspring.profiles.active=${profile}", "gateway-service.jar"]