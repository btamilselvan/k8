FROM eclipse-temurin:21-jre-alpine

ENV profile=dev

# Add the application's jar to the container
COPY target/cloud-config-server.jar /app/cloud-config-server.jar

WORKDIR /app

# Run the jar file 
ENTRYPOINT ["java", "-jar", "cloud-config-server.jar"]