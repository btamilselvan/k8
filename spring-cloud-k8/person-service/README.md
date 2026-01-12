# Person Service

A Spring Boot microservice demonstrating service discovery, inter-service communication, and configuration management across Kubernetes, Docker, and local environments.

## Key Features

### Service Discovery
- **Kubernetes Discovery**: Automatic service discovery using Spring Cloud Kubernetes
- **DiscoveryClient Integration**: Programmatic service discovery and instance listing
- **Multi-Environment Support**: Different discovery mechanisms for local, Docker, and Kubernetes environments

### Inter-Service Communication
- **Feign Client**: Declarative HTTP client for calling address-service
- **RestClient**: Direct HTTP calls using service discovery
- **Load Balancing**: Spring Cloud LoadBalancer integration for client-side load balancing
- **Multiple URL Patterns**: Support for K8s short URLs and fully qualified domain names

### Configuration Management
- **Kubernetes ConfigMaps**: External configuration via K8s ConfigMaps
- **Kubernetes Secrets**: Secure credential management via K8s Secrets
- **Profile-Based Config**: Environment-specific configurations (local, docker, kubernetes)

## Architecture

```
┌─────────────────┐    ┌──────────────────┐
│  Person Service │────│  Address Service │
│                 │    │                  │
│ - DiscoveryClient│    │ - Health endpoint│
│ - Feign Client   │    │ - Service registry│
│ - RestClient     │    │                  │
└─────────────────┘    └──────────────────┘
```

## API Endpoints

| Endpoint | Description | Environment |
|----------|-------------|-------------|
| `/health` | Service health check | All |
| `/config` | Display configuration values | All |
| `/secret` | Display secret values | All |
| `/services` | List discovered services | All |
| `/address-service` | Call address-service via DiscoveryClient | All |
| `/address-service/feign` | Call address-service via Feign | All |
| `/address-service/k8/internal/short` | Call via K8s short URL | Kubernetes |
| `/address-service/k8/internal/full` | Call via K8s FQDN | Kubernetes |

## Environment Configurations

### Kubernetes Environment
- **Service Discovery**: Automatic via Kubernetes API
- **Configuration**: ConfigMaps and Secrets
- **Load Balancing**: Kubernetes Service + Spring Cloud LoadBalancer
- **Internal URLs**: 
  - Short: `http://address-service:8080`
  - FQDN: `http://address-service.default.svc.cluster.local:8080`

### Docker Compose Environment
- **Service Discovery**: Static service instances
- **Configuration**: Environment variables
- **Load Balancing**: Limited (single instance per service)
- **Internal URLs**: `http://address-service:8080`

### Local Development
- **Service Discovery**: Static localhost URLs
- **Configuration**: Application properties
- **Load Balancing**: Not applicable (single instances)
- **Internal URLs**: `http://localhost:8082`

## Dependencies

```xml
<!-- Service Discovery -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-kubernetes-client</artifactId>
</dependency>

<!-- Feign Client -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-openfeign</artifactId>
</dependency>

<!-- Load Balancing -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-loadbalancer</artifactId>
</dependency>

<!-- Kubernetes Config -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-kubernetes-client-config</artifactId>
</dependency>
```

## Running the Service

### Local Development
```bash
mvn spring-boot:run -Dspring-boot.run.profiles=local
```

### Docker Compose
```bash
docker-compose up person-service
```

### Kubernetes
```bash
kubectl apply -f k8s/person-service-deployment.yaml
```

## Configuration Examples

### Kubernetes Profile
```yaml
spring:
  config.activate.on-profile: kubernetes
  config.import: "kubernetes:"
  cloud:
    kubernetes:
      discovery:
        namespaces: [default]
        service-labels:
          discovery-enabled: "true"
```

### Docker Profile
```yaml
spring:
  config.activate.on-profile: docker
  cloud:
    discovery:
      client:
        simple:
          instances:
            address-service:
              - uri: http://address-service:8080
```

## Service Communication Patterns

### 1. Feign Client (Recommended)
```java
@FeignClient(name = "address-service")
public interface AddressServiceClient {
    @GetMapping("/health")
    String health();
}
```

### 2. DiscoveryClient + RestClient
```java
List<ServiceInstance> instances = discoveryClient.getInstances("address-service");
ServiceInstance instance = instances.get(0);
String url = "http://" + instance.getHost() + ":" + instance.getPort() + "/health";
String response = restClient.get().uri(url).retrieve().body(String.class);
```

### 3. Direct Kubernetes URLs
```java
// Short URL (same namespace)
String response = restClient.get()
    .uri("http://address-service:8080/health")
    .retrieve().body(String.class);

// FQDN (cross-namespace)
String response = restClient.get()
    .uri("http://address-service.default.svc.cluster.local:8080/health")
    .retrieve().body(String.class);
```

## Build and Deployment

### Maven Build
```bash
# Build specific module
mvn clean package -pl person-service -am -DskipTests

# Build with dependencies
mvn clean package spring-boot:repackage
```

### Docker Build
```bash
docker build --build-arg MODULE_NAME=person-service -t person-service:latest .
```

## Monitoring and Observability

- **Health Checks**: Built-in health endpoint
- **Service Discovery**: Real-time service listing
- **Configuration Visibility**: Config and secret endpoints for debugging
- **Logging**: Comprehensive logging for service calls and discovery

## Best Practices Demonstrated

1. **Environment Separation**: Different configurations for local, Docker, and Kubernetes
2. **Service Abstraction**: Feign clients hide HTTP complexity
3. **Resilience**: Multiple communication patterns for different scenarios
4. **Security**: Secrets management via Kubernetes Secrets
5. **Observability**: Health checks and service discovery endpoints
6. **Configuration Management**: External configuration via ConfigMaps

## Troubleshooting

### Service Discovery Issues
- Check service labels match discovery configuration
- Verify RBAC permissions for Kubernetes API access
- Ensure services are in the correct namespace

### Communication Failures
- Verify target service is running and healthy
- Check network policies and security groups
- Validate service names and ports

### Configuration Problems
- Confirm ConfigMaps and Secrets exist in correct namespace
- Check profile activation
- Verify property names match expected values