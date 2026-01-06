- For some reason, the route configuration in application.yaml in gateway-service does not work. The routes are configured in GatewayServiceConfig as a beam methods.
- ```spring-cloud-function-context``` will allows to expose Function beans which can be exposed as HTTP endpoints. See, pom.xml in gateway-service.java.
- We are using Spring cloud gateway MVC for this POC.
- Some important application config values and secrets are stored in K8 configMaps and K8 secrets.
- See, gateway-service/src/main/resources/application.yml for application config values.

- mvn clean package -pl xyz-service -am -DskipTests
    - ``` -pl ``` “Build ONLY this module”
    - ``` -am ``` “Also build what this module depends on”

- ```RUN --mount=type=cache,target=/root/.m2 mvn dependency:go-offline -B``` 
- --mount=type=cache - Tells Docker to create a special temporary storage area that survives across different builds. Unlike a standard layer, if the Dockerfile changes, this cache is not wiped.
target=/root/.m2: This is the directory inside the container that Maven uses to store its local repository (downloaded dependencies).

- Run ```docker compose build``` from the root directory to build the images.

#### Using Local Docker Image with Minikube:
```
eval $(minikube docker-env)  # Switch to Minikube's Docker daemon
docker build -t springboot-demo:1.0 .
```
This builds the image directly into Minikube’s environment—no need for a registry.

