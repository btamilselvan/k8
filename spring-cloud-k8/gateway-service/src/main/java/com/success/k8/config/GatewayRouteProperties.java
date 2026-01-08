package com.success.k8.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "gateway.routes")
@Getter
@Setter
public class GatewayRouteProperties {

  private String personServiceUri;
  private String addressServiceUri;
}
