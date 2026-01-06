package com.success.k8.config;


import org.springframework.cloud.gateway.server.mvc.filter.BeforeFilterFunctions;
import org.springframework.cloud.gateway.server.mvc.handler.GatewayRouterFunctions;
import org.springframework.cloud.gateway.server.mvc.handler.HandlerFunctions;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.web.servlet.function.RequestPredicates;
import org.springframework.web.servlet.function.RouterFunction;
import org.springframework.web.servlet.function.ServerResponse;

/**
 * This is a demo configuration class to setup various routes in the Gateway Service via code. In
 * real world scenarios, these routes can be configured via application.yml or properties file.
 */
@Configuration
public class GatewayServiceConfig {

  // Expose the "concat" Function as an HTTP GET endpoint at /concat1
  @Bean
  public RouterFunction<ServerResponse> route1() {
    return GatewayRouterFunctions.route("contact_function_router")
        .POST("/concat1", HandlerFunctions.fn("concat"))
        .build();
  }

  // Forward all requests with path /web to /uppercase function
  @Bean
  public RouterFunction<ServerResponse> route2() {
    return GatewayRouterFunctions.route("uppercase_function_router")
        .GET("/web", HandlerFunctions.forward("/uppercase"))
        .build();
  }

  // Forward all requests with path /person/** to person-service
  /*@Bean
  public RouterFunction<ServerResponse> route6() {
    return GatewayRouterFunctions.route("person_service_router_1")
        .GET("/person/**", HandlerFunctions.http())
        .before(BeforeFilterFunctions.rewritePath("/person/(?<segment>.*)", "/${segment}"))
        .before(BeforeFilterFunctions.uri("http://localhost:8081"))
        .build();
  }*/

  // forward /xyz to google.com
  @Bean
  public RouterFunction<ServerResponse> route4() {
    return GatewayRouterFunctions.route("simple_web_router")
        .route(RequestPredicates.path("/xyz"), HandlerFunctions.http())
        .before(BeforeFilterFunctions.uri("https://google.com"))
        .build();
  }

  // routes all GET requests with header x-google to google.com
  @Bean
  public RouterFunction<ServerResponse> route5() {
    return GatewayRouterFunctions.route("simple_web_router_post")
        .route(
            RequestPredicates.method(HttpMethod.GET)
                .and(RequestPredicates.headers(headers -> !headers.header("x-google").isEmpty())),
            HandlerFunctions.http())
        .before(BeforeFilterFunctions.uri("https://google.com"))
        .build();
  }

  @Bean
  public RouterFunction<ServerResponse> customRoutes() {
    return GatewayRouterFunctions.route("person_address_router")
        .path(
            "/person/**",
            builder -> {
              builder
                  .route(RequestPredicates.all(), HandlerFunctions.http())
                  .before(
                      BeforeFilterFunctions.rewritePath("/person/(?<segment>.*)", "/${segment}"))
                  .before(BeforeFilterFunctions.uri("http://person-service:8080"));
            })
        .path(
            "/address/**",
            builder -> {
              builder
                  .route(RequestPredicates.all(), HandlerFunctions.http())
                  .before(
                      BeforeFilterFunctions.rewritePath("/address/(?<segment>.*)", "/${segment}"))
                  .before(BeforeFilterFunctions.uri("http://address-service:8080"));
            })
        .build();
  }
}