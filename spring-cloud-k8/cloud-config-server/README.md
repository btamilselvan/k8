# Cloud Config Server

A Spring Cloud Config Server that demonstrates configuration management capabilities across different deployment environments: local development, Docker containers, and Kubernetes clusters.

## Overview

This project showcases how to configure and deploy a Spring Cloud Config Server that can serve configuration from multiple backends based on the deployment environment:

- **Local Development**: Serves configuration from local filesystem (native profile)
- **Docker Environment**: Connects to Git repository for configuration
- **Kubernetes Environment**: Can serve from either K8s ConfigMaps/Secrets or Git repository

## Project Structure

```
cloud-config-server/
├── src/main/java/com/success/k8/
│   └── ConfigServerApplication.java    # Main application class with @EnableConfigServer
├── src/main/resources/
│   ├── application.yaml                # Multi-profile configuration
│   └── config/
│       └── config.properties          # Local configuration files
├── Dockerfile                         # Multi-stage Docker build
└── pom.xml                           # Maven dependencies
```

## Environment-Specific Configuration

### 1. Local Development (Native Profile)

**Profile**: `native` or `local`

**Configuration Source**: Local filesystem

**How to Run**:
```bash
java -jar cloud-config-server.jar --spring.profiles.active=native
```

**Configuration**:
- Serves files from `src/main/resources/config/` directory
- No external dependencies required
- Ideal for development and testing

**Test URL**: `http://localhost:8888/config/default`

### 2. Docker Environment (Git Profile)

**Profile**: `dev` or `docker`

**Configuration Source**: Git repository

**How to Run**:
```bash
docker build -t config-server --build-arg MODULE_NAME=cloud-config-server .
docker run -p 8888:8888 -e SPRING_PROFILES_ACTIVE=dev config-server
```

**Configuration**:
- Connects to Git repository: `https://github.com/btamilselvan/spring-cloud-config-repo.git`
- Uses `dev` branch as default label
- SSL validation is skipped for development

### 3. Kubernetes Environment

The config server supports two modes in Kubernetes:

#### 3a. Kubernetes Native (ConfigMaps & Secrets)

**Profile**: `kubernetes_native`

**Configuration Source**: K8s ConfigMaps and Secrets

**Dependencies Required**:
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-kubernetes-configserver</artifactId>
</dependency>
```

**Configuration**:
- Reads from ConfigMaps and Secrets in `default` namespace
- Requires RBAC permissions to access K8s API
- Enable with: `spring.cloud.kubernetes.configserver.enabled: true`

#### 3b. Kubernetes with Git Backend

**Profile**: `kubernetes_git`

**Configuration Source**: Git repository (same as Docker)

**Configuration**:
- Uses standard Git backend while running in K8s
- No K8s-specific dependencies required
- Suitable when you want centralized Git-based config in K8s

## Dependencies

### Core Dependencies
```xml
<!-- Essential for all environments -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-config-server</artifactId>
</dependency>

<!-- For monitoring and health checks -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

### Kubernetes-Specific (Optional)
```xml
<!-- Only needed for kubernetes_native profile -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-kubernetes-configserver</artifactId>
</dependency>
```

## Configuration Backend Comparison

| Feature         | Local (Native)                 | Git                                | Kubernetes ConfigMaps             |
|-----------------|--------------------------------|------------------------------------|-----------------------------------|
| Active Profile  | `native`, `local`              | `dev`, `docker`, `kubernetes_git`  | `kubernetes_native`               |
| Backend Storage | Local filesystem               | Remote Git repository              | K8s ConfigMaps and Secrets        |
| Setup Property  | `search-locations: file:/path` | `uri: https://github.com/...`      | `configserver.enabled: true`      |
| Versioning      | Manual file management         | Git branches, tags, commits        | K8s resource versioning           |
| Security        | OS-level permissions           | SSH keys, access tokens           | RBAC permissions                  |
| External Deps   | None                           | Git repository access              | K8s cluster access                |

## URL Patterns and Lookup Logic

| Backend       | URL Pattern                              | Lookup Logic                                           |
|---------------|------------------------------------------|-------------------------------------------------------|
| Git           | `/{application}/{profile}/{label}`       | Clones repo, checks out label, finds files           |
| Native        | `/{application}/{profile}`               | Searches local directory for matching files          |
| Kubernetes    | `/{application}/{profile}`               | Queries K8s API for ConfigMaps by name               |

### Example URLs

- **Git**: `http://localhost:8888/person-service/dev/main`
- **Native**: `http://localhost:8888/person-service/dev`
- **Kubernetes**: `http://localhost:8888/person-service/kubernetes`

## Building and Deployment

### Maven Build
```bash
mvn clean package -pl cloud-config-server -am
```

### Docker Build
```bash
docker build -t config-server --build-arg MODULE_NAME=cloud-config-server .
```

### Kubernetes Deployment
1. Ensure proper RBAC permissions for ConfigMap/Secret access
2. Deploy with appropriate profile: `kubernetes_native` or `kubernetes_git`
3. Configure service discovery for other microservices

## Monitoring

Actuator endpoints are enabled for monitoring:
- Health: `http://localhost:8888/actuator/health`
- Info: `http://localhost:8888/actuator/info`
- All endpoints: `http://localhost:8888/actuator`

**Note**: In production, limit actuator endpoint exposure for security.

## Usage Examples

### Testing Configuration Retrieval
```bash
# Test native profile
curl http://localhost:8888/config/default

# Test specific application config
curl http://localhost:8888/person-service/dev

# Test with specific label (Git only)
curl http://localhost:8888/person-service/dev/main
```

## Best Practices

1. **Environment Separation**: Use different profiles for different environments
2. **Security**: Never expose sensitive actuator endpoints in production
3. **RBAC**: Configure proper Kubernetes RBAC for ConfigMap access
4. **Git Security**: Use SSH keys or personal access tokens for private repositories
5. **Caching**: Consider enabling configuration caching for better performance