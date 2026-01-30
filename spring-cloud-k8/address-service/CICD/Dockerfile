FROM eclipse-temurin:21-jre-alpine

ENV profile=dev

# Add the application's jar to the container
COPY target/address-service.jar /app/address-service.jar

WORKDIR /app

# Run the jar file 
ENTRYPOINT ["java", "-jar", "address-service.jar"]