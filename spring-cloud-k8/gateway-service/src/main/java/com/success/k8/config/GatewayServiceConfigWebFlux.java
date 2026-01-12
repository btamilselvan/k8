package com.success.k8.config;

import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class GatewayServiceConfigWebFlux {

  private final GatewayRouteProperties gatewayRoutes;

  public GatewayServiceConfigWebFlux(GatewayRouteProperties gatewayRoutes) {
    this.gatewayRoutes = gatewayRoutes;
  }

  @Bean
  public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {

    //remove path prefix (/person, /address) before forwarding to downstream service
    return builder
        .routes()
        .route(
            "person-service",
            r ->
                r.path("/person/**")
                    .filters(f -> f.rewritePath("/person/(?<segment>.*)", "/${segment}"))
                    .uri(gatewayRoutes.getPersonServiceUri()))
        .route(
            "address-service",
            r ->
                r.path("/address/**")
                    .filters(f -> f.rewritePath("/address/(?<segment>.*)", "/${segment}"))
                    .uri(gatewayRoutes.getAddressServiceUri()))
        .route(
            "config-server",
            r ->
                r.path("/config/**")
                    .filters(f -> f.rewritePath("/config/(?<segment>.*)", "/${segment}"))
                    .uri(gatewayRoutes.getConfigServerUri()))
        .build();
  }
}
