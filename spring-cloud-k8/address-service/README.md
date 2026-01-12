# Address Service - Config Client Demo

The address-service demonstrates Spring Cloud Config Client capabilities with fail-fast, retry mechanisms, and multi-environment support across Kubernetes, Docker, and local environments.

## Config Client Features

### Fail-Fast Configuration
- **Enabled**: `spring.cloud.config.fail-fast=true`
- Service will halt with an Exception if it cannot connect to Config Server
- Ensures configuration integrity at startup

### Retry Mechanism
Configured with exponential backoff:
```yaml
spring.cloud.config.retry:
  max-attempts: 5
  max-interval: 3000
  initial-interval: 1000
  multiplier: 1.5
```

### Multi-Environment Support

#### Local Environment
- **Profile**: `local`
- **Config Server**: `http://localhost:8888`
- **Labels**: `dev,local`
- **Port**: 8082

#### Docker Environment
- **Profile**: `docker`
- **Config Server**: `http://cloud-config-server:8888`
- **Labels**: `dev`
- **Port**: 8080
- **Replicas**: 2 (via docker-compose)

#### Kubernetes Environment
- **Profile**: `kubernetes`
- **Config Server**: `http://cloud-config-server`
- **Labels**: `kubernetes`
- **Port**: 8080
- **Replicas**: 2
- **Config Sources**: K8s ConfigMaps and Secrets

## Configuration Sources

### Properties from Config Server
- `hello.message` - Greeting message
- `trocks.apiKey` - API key from secrets

### Endpoints
- `GET /health` - Health check endpoint
- `GET /config` - Display configuration values

## Dependencies

### Core Config Client
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-config</artifactId>
</dependency>
```

### Retry Support
```xml
<dependency>
    <groupId>org.springframework.retry</groupId>
    <artifactId>spring-retry</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-aop</artifactId>
</dependency>
```

## Running the Service

### Local Development
```bash
mvn spring-boot:run -Dspring-boot.run.profiles=local
```

### Docker Compose
```bash
docker-compose up address-service
```

### Kubernetes
```bash
kubectl apply -f deployment/
```

## Key Configuration Concepts

- **spring.config.import**: Connects to Config Server with optional prefix for graceful degradation
- **spring.cloud.config.label**: Sets the branch/label for configuration retrieval
- **Profile-specific configs**: Different Config Server URLs and labels per environment
- **Dependency on Config Server**: Docker and K8s deployments wait for Config Server health check