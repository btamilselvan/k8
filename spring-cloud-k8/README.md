# Spring Cloud Gateway Microservices Demo

A comprehensive demonstration of Spring Cloud Gateway with multi-environment support (Kubernetes, Docker Compose, and local development).

## Project Structure

- **gateway-service** - API Gateway with routing, load balancing, and service discovery
- **person-service** - Microservice with Feign client integration
- **address-service** - Downstream microservice
- **cloud-config-server** - Centralized configuration management

## Gateway Service Features

### Routing & Load Balancing
- **WebFlux-based Gateway** - Uses Spring Cloud Gateway WebFlux for reactive routing
- **Path-based Routing** - Routes requests based on path prefixes (`/person/**`, `/address/**`, `/config/**`)
- **Path Rewriting** - Strips service prefixes before forwarding (e.g., `/person/health` → `/health`)
- **Load Balancing** - Uses `lb://` URIs with Spring Cloud LoadBalancer

### Service Discovery
- **Kubernetes Discovery** - Auto-discovers services using `spring-cloud-starter-kubernetes-client`
- **Docker Compose Discovery** - Uses simple discovery client with static service URIs
- **Local Development** - Configures localhost URIs for local testing

### Multi-Environment Configuration
- **Profile-based Configuration** - Supports `kubernetes`, `docker`, and `local` profiles
- **Environment-specific URIs** - Different service URIs per environment
- **Centralized Properties** - Uses `GatewayRouteProperties` for configuration management

### Function Endpoints
- **Spring Cloud Functions** - Exposes `uppercase` and `concat` functions as HTTP endpoints
- **Health Check** - Custom health endpoint at `/health`
- **Actuator Integration** - Management endpoints for monitoring

## Build & Run

### Maven Build
```bash
# Build specific service
mvn clean package -pl gateway-service -am -DskipTests

# Build all services
mvn clean package -DskipTests
```

### Running Locally
```bash
# Start services in order
java -jar cloud-config-server/target/cloud-config-server-1.0-SNAPSHOT.jar --spring.profiles.active=local
java -jar address-service/target/address-service-1.0-SNAPSHOT.jar --spring.profiles.active=local
java -jar person-service/target/person-service-1.0-SNAPSHOT.jar --spring.profiles.active=local
java -jar gateway-service/target/gateway-service-1.0-SNAPSHOT.jar --spring.profiles.active=local
```

### Docker Compose
```bash
# Build and start all services
docker compose build
docker compose up -d
```

### Kubernetes Deployment
```bash
# Build images for Minikube
eval $(minikube docker-env)
docker compose build

# Deploy to Kubernetes
kubectl apply -f k8s/
```

## API Endpoints

### Gateway Service (Port 8080)
- `GET /health` - Gateway health check
- `GET /ucase` - Uppercase function endpoint
- `POST /concat1` - Concatenation function endpoint
- `GET /actuator/**` - Management endpoints

### Routed Services
- `GET /person/**` - Routes to person-service
- `GET /address/**` - Routes to address-service  
- `GET /config/**` - Routes to config-server

### Example Requests
```bash
# Direct gateway endpoints
curl http://localhost:8080/health
curl http://localhost:8080/ucase

# Routed requests
curl http://localhost:8080/person/health
curl http://localhost:8080/address/health
curl http://localhost:8080/config/person-service/kubernetes
```

## Key Implementation Details

### Gateway Configuration
- **Route Configuration** - Routes are configured programmatically in `GatewayServiceConfigWebFlux` using `RouteLocator`
- **YAML Configuration** - Application YAML route configuration is commented out (known limitation)
- **WebFlux vs WebMVC** - Currently uses WebFlux; WebMVC configuration available in `GatewayServiceConfig`

### Service Discovery
- **Kubernetes** - Uses `spring-cloud-starter-kubernetes-client` with service labels for auto-discovery
- **Docker** - Uses simple discovery client with static service definitions
- **Load Balancing** - Requires `spring-cloud-starter-loadbalancer` dependency for `lb://` URIs

### Configuration Management
- **Spring Cloud Config** - Centralized configuration using config-server
- **Kubernetes ConfigMaps** - Can read directly from K8s ConfigMaps and Secrets
- **Profile Activation** - Kubernetes profile auto-activated when running in cluster

### Docker Optimization
- **Maven Cache** - Uses Docker build cache for Maven dependencies
- **Multi-stage Builds** - Optimized Dockerfile with dependency caching
- **Health Checks** - Docker Compose includes health check configurations

## Environment-Specific Configurations

### Kubernetes Environment
- **Service Discovery** - Auto-discovers services in `default` namespace with `discovery-enabled: "true"` label
- **Service URLs** - Uses `lb://service-name` format for load balancing
- **Profile Activation** - `kubernetes` profile auto-activated when running in cluster
- **RBAC** - Requires proper permissions to access ConfigMaps and Secrets

### Docker Compose Environment
- **Static Discovery** - Uses simple discovery client with predefined service instances
- **Service URLs** - Maps to Docker service names (e.g., `http://person-service:8080`)
- **Health Checks** - Includes health check configurations for service dependencies
- **Replicas** - Supports multiple replicas (e.g., address-service has 2 replicas)

### Local Development
- **Localhost URLs** - Services run on different ports (8080, 8081, 8082, 8888)
- **Simple Configuration** - Minimal setup for local testing
- **Config Server** - Local file-based configuration support

## Important Notes

### Path Rewriting
- Gateway strips service prefixes: `/person/health` → `/health`
- Configured using `rewritePath` filter in route definitions
- Essential for proper request forwarding to downstream services

### Service URLs
- **Kubernetes**: `{service-name}.{namespace}.svc.cluster.local:{port}`
- **Internal Traffic**: Uses port 80 for K8s services
- **Load Balancing**: Requires `lb://` prefix for Spring Cloud LoadBalancer

### Configuration Server
- **Local**: File-based configuration in `src/main/resources/config`
- **Git**: Remote repository with branch/tag support
- **Kubernetes**: ConfigMaps and Secrets integration
- **Access URL**: `http://api.localhost/config/person-service/kubernetes`

## Architecture & Request Flow

```
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
│ - Path rewriting filters  │
│ - Service discovery       │
│ - Function endpoints      │
└─────┬─────────────────────┘
      │ lb://person-service
      ▼
┌───────────────────────────┐
│ Person-Service Pods       │
│ - Feign client calls      │
│ - Circuit breaker         │
│ - Multiple replicas       │
└─────┬─────────────────────┘
      │ lb://address-service
      ▼
┌───────────────────────────┐
│ Address-Service Pods      │
│ - Business logic          │
│ - Multiple replicas       │
└───────────────────────────┘
```

## Load Balancing & Service Discovery

### Load Balancing Layers
| Layer                     | Scope              | Responsibility                    |
|---------------------------|--------------------|-----------------------------------|
| Kubernetes Service        | TCP connection     | L4 load balancing (kube-proxy)   |
| Ingress                   | HTTP request       | External HTTP routing             |
| Spring Cloud Gateway      | HTTP request       | API routing, filters, functions   |
| Spring Cloud LoadBalancer | Instance selection | L7 request-level load balancing   |

### Service Discovery Comparison
| Feature       | Native K8s (`http://service`) | Spring Discovery (`lb://service`) |
|---------------|--------------------------------|-----------------------------------|
| Load Balancer | Kubernetes (kube-proxy)        | Spring Cloud LoadBalancer         |
| Logic         | L4 (Connection-based)          | L7 (Request-based)                |
| Visibility    | Single Service IP              | Individual Pod IPs                |
| RBAC Required | No                             | Yes (to list endpoints)           |
| Configuration | DNS-based                      | Discovery client                  |

### URL Formats by Environment
| Environment | URL Format                                    | Example                           |
|-------------|-----------------------------------------------|-----------------------------------|
| Local       | `http://localhost:<port>`                     | `http://localhost:8081`           |
| Docker      | `http://<service-name>:<port>`                | `http://person-service:8080`      |
| Kubernetes  | `lb://<service-name>`                         | `lb://person-service`             |
| K8s Full    | `http://<service>.<ns>.svc.cluster.local`    | `http://person-service.default.svc.cluster.local` |

## Configuration Management

### Config Server Backends
| Feature         | Local (Native)                 | Git                                | Kubernetes                        |
|-----------------|--------------------------------|------------------------------------|-----------------------------------|
| Active Profile  | `native`                       | `git` (default)                    | `kubernetes`                      |
| Backend Storage | Local filesystem               | Remote Git repository              | K8s ConfigMaps and Secrets        |
| Setup Property  | `search-locations: file:/path` | `uri: https://github.com/...`      | `configserver.enabled: true`      |
| Versioning      | Manual file management         | Git branches, tags, commits        | Kubernetes API versioning         |
| Security        | OS-level permissions           | SSH keys, access tokens           | RBAC (Role-Based Access Control)  |

### Config Server URL Patterns
| Backend    | Application                    | Profile                      | Label                           | Example URL                                   |
|------------|--------------------------------|------------------------------|--------------------------------|-----------------------------------------------|
| Git        | Service name                   | Environment (dev, prod)      | Branch/Tag (main, v1.0)       | `http://localhost:8888/person-service/dev/main` |
| Native     | Local file name                | Profile suffix               | Ignored/Sub-folder             | `http://localhost:8888/person-service/dev/`     |
| Kubernetes | ConfigMap name                 | Profile-specific ConfigMaps  | Ignored                        | `http://localhost:8888/person-service/kubernetes` |

### Config Lookup Logic
| Backend    | Lookup Strategy                                                                                    |
|------------|----------------------------------------------------------------------------------------------------|
| Git        | Clone repository → checkout {label} → find `application-{profile}.yml`                           |
| Native     | Search local directories → find `application-{profile}.properties` or `.yml`                     |
| Kubernetes | Query K8s API → find ConfigMap `{application}` and `{application}-{profile}` if profile specified |

## Dependencies

### Gateway Service Key Dependencies
```xml
<!-- WebFlux Gateway -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-gateway-server-webflux</artifactId>
</dependency>

<!-- Kubernetes Service Discovery -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-kubernetes-client</artifactId>
</dependency>

<!-- Load Balancing -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-loadbalancer</artifactId>
</dependency>

<!-- Actuator for Management -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

## References
- [Spring Cloud Kubernetes](https://cloud.spring.io/spring-cloud-kubernetes/reference/html/)
- [Spring Cloud Gateway](https://docs.spring.io/spring-cloud-gateway/docs/current/reference/html/)
- [Kubernetes Service Discovery](https://docs.spring.io/spring-cloud-kubernetes/reference/discovery-client.html)
- [Spring Cloud LoadBalancer](https://docs.spring.io/spring-cloud-commons/docs/current/reference/html/#spring-cloud-loadbalancer)
- [Spring Cloud Config](https://docs.spring.io/spring-cloud-config/docs/current/reference/html/)