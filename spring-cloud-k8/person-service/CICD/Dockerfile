FROM eclipse-temurin:21-jre-alpine

# Add the application's jar to the container
COPY target/person-service.jar /app/person-service.jar

WORKDIR /app

# Run the jar file 
ENTRYPOINT ["java", "-jar", "person-service.jar"]