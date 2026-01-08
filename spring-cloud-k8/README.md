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

- There is no need for a separate discovery server as k8 provides out of the box service discovery. The gateway can forward the requests to the downstream services using the DNS name (e.g. http://person-service), however to enable load balancing, we need to use lb://person-service url and add 'spring-cloud-starter-loadbalancer' dependency. In addition to this, we want to make gateway automatically discover the available services from k8. this can be done by adding the following dependency, 'spring-cloud-starter-kubernetes-client' and providing the k8 namespace information and service-labels in application.yml. The service-labels should match the meta.labels included in the k8 deployment configuration.

- To get true load balancing in a Docker Compose environment without fighting JVM DNS caching or manual YAML lists: Add the NGINX Load Balancer and Point the Feign Client to the NGINX address instead of the service name directly.

#### Using Local Docker Image with Minikube:
```
eval $(minikube docker-env)  # Switch to Minikube's Docker daemon
docker build -t springboot-demo:1.0 .
```
This builds the image directly into Minikube’s environment—no need for a registry.

- By default Spring Cloud Kubernetes will enable the kubernetes profile when it detects it is running inside a Kubernetes cluster.

- Make sure to review the rewrite path. e.g. a request to gateway with path /person/health should be forwarded to person-serive after stripping /person from the path. http://api.localhost/person/health -> http://person-service/health

- the k8 service port is 80. the internal traffic are routed thru k8 services so no need to specify the port in the internal requests.

- We can't get true load balancing without a Discovery server (Netflix Eureka or HashiCorp Consul) or a proxy server like NGINX. If we want true load balancing where traffic actually moves between our Docker containers without setting up NGINX or Kubernetes, using a Discovery Server is the best path. It makes our Docker environment behave almost exactly like a local version of a cloud environment.

## Workflow
┌─────────┐
│ Client  │
└─────┬───┘
      │ HTTP/HTTPS
      ▼
┌───────────────┐
│ Ingress       │
│ (NGINX / ALB) │
└─────┬─────────┘
      │ Routes based on host/path
      ▼
┌───────────────────────────┐
│ Spring Cloud Gateway Pod  │
│ - RouteLocator (lb://)    │
│ - Global auth / filters   │
│ - Optional per-request LB │
└─────┬─────────────────────┘
      │ DNS: http://person-service
      ▼
┌───────────────────────────┐
│ Person-Service Pods       │
│ - Multiple replicas       │
│ - Circuit breaker wraps   │
│   calls to downstream     │
└─────┬─────────────────────┘
      │ DNS: http://address-service
      ▼
┌───────────────────────────┐
│ Address-Service Pods      │
│ - Multiple replicas       │
│ - Optional retries / CB   │
└───────────────────────────┘

## Who does what
| Layer                     | Load-balancing scope |
|---------------------------|----------------------|
| Kubernetes Service        | TCP connection       |
| Ingress                   | HTTP request         |
| Spring Cloud Gateway      | HTTP request         |
| Spring Cloud LoadBalancer | Instance selection   |


## Who Is Responsible for Load Balancing?
| Layer       | Responsibility             |
|-------------|----------------------------|
| Ingress     | External HTTP routing      |
| Gateway     | API routing, auth, filters |
| K8s Service | TCP load balancing         |
| App         | Business logic             |


## Summary Table for URL Discovery

| Scope           | URL Format                                                  |
|-----------------|-------------------------------------------------------------|
| Same Namespace  | http://address-service:<port>                               |
| Cross Namespace | http://address-service.<namespace>:<port>                   |
| Most Robust     | http://address-service.<namespace>.svc.cluster.local:<port> |
| App             | Business logic                                              |


| Feature       | Native K8s URL (http://address-service) | Spring Discovery (lb://address-service)  |
|---------------|-----------------------------------------|------------------------------------------|
| Who Balances? | Kubernetes (kube-proxy)                 | Your Java App (Spring LoadBalancer)      |
| Logic         | L4 (Connection based)                   | L7 (Request based)                       |
| Visibility    | App sees 1 Service IP                   | App sees every individual Pod IP         |
| RBAC          | Not required                            | Required (to list endpoints)             |


# References
- https://cloud.spring.io/spring-cloud-kubernetes/reference/html/
- https://docs.spring.io/spring-cloud-kubernetes/reference/discovery-client.html