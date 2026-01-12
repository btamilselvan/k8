# Gateway Service

Spring Cloud Gateway with multi-environment support for routing and load balancing.

## Features

- **WebFlux-based Gateway** - Reactive routing with Spring Cloud Gateway
- **Path-based Routing** - Routes `/person/**`, `/address/**`, `/config/**`
- **Path Rewriting** - Strips service prefixes before forwarding
- **Multi-Environment Support** - Kubernetes, Docker, and local profiles
- **Service Discovery** - Auto-discovery in Kubernetes, static URIs for Docker/local

## Configuration

Routes are configured programmatically in `GatewayServiceConfigWebFlux` using `RouteLocator`. Service URIs are managed via `GatewayRouteProperties`.

### Environment Profiles

| Profile | Service Discovery | Example URI |
|---------|------------------|-------------|
| `kubernetes` | Kubernetes client | `lb://person-service` |
| `docker` | Simple discovery | `lb://person-service` |
| `local` | Simple discovery | `lb://person-service` |

## Endpoints

- `GET /health` - Gateway health check
- `GET /ucase` - Test endpoint
- `GET /actuator/**` - Management endpoints

## Routing

- `/person/**` → person-service (strips `/person` prefix)
- `/address/**` → address-service (strips `/address` prefix)  
- `/config/**` → cloud-config-server (strips `/config` prefix)

## Dependencies

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-gateway-server-webflux</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-kubernetes-client</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-loadbalancer</artifactId>
</dependency>
```

## Running

```bash
# Local
java -jar target/gateway-service-1.0-SNAPSHOT.jar --spring.profiles.active=local

# Docker
docker run -e SPRING_PROFILES_ACTIVE=docker gateway-service

# Kubernetes (auto-detects profile)
kubectl apply -f deployment.yaml
```