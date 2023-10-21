#########################################################
# Prometheus Operator which has Prometheus and Grafana

module "charts_prometheus_operator" {
  source  = "streamnative/charts/helm//modules/prometheus-operator"
  version = "0.8.6"

  values = [
    <<-EOF
  prometheus:
    prometheusSpec:
      additionalScrapeConfigs:
      - job_name: graylog-job
        scrape_interval: 15s
        kubernetes_sd_configs:
        - role: service
          namespaces:
            names:
            - default
        relabel_configs:
        - source_labels: [__meta_kubernetes_service_name]
          action: keep
          regex: graylog
        - source_labels: [__meta_kubernetes_service_cluster_ip]
          action: replace
          target_label: __address__
          replacement: $1:5000
EOF
  ]
}


resource "kubectl_manifest" "monitoring_ingress" {
  depends_on = [
    module.charts_prometheus_operator
  ]

  yaml_body = <<-EOF
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: "monitoring-ingress"
    namespace: "monitoring"
    annotations:
      kubernetes.io/ingress.global-static-ip-name: public-ip
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/target-type: ip
      # Health Check Settings
      alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
      alb.ingress.kubernetes.io/healthcheck-port: traffic-port
      #alb.ingress.kubernetes.io/tags: Name=${local.name}-monitoring-ingress
      #Important Note:  Need to add health check path annotations in service level if we are planning to use multiple targets in a load balancer
      alb.ingress.kubernetes.io/healthcheck-path: /
      alb.ingress.kubernetes.io/healthcheck-interval-seconds: "15"
      alb.ingress.kubernetes.io/healthcheck-timeout-seconds: "5"
      alb.ingress.kubernetes.io/success-codes: "200"
      alb.ingress.kubernetes.io/healthy-threshold-count: "2"
      alb.ingress.kubernetes.io/unhealthy-threshold-count: "2"
      ## SSL Settings
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
      alb.ingress.kubernetes.io/certificate-arn: ${aws_acm_certificate.this.arn} # ACM ARN
      # SSL Redirect Setting
      alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
      # Merge all ingresses
      alb.ingress.kubernetes.io/group.name: graylog-group
      # Route53 Settings
      external-dns.alpha.kubernetes.io/hostname: ${local.domain_name}
      
  spec:
    ingressClassName: alb
    rules:
      - host: prom.${local.domain_name}
        http:
          paths:
            - path: /
              pathType: Prefix
              backend:
                service:
                  name: prometheus-operated
                  port:
                    name: http-web
      - host: grafana.${local.domain_name}
        http:
          paths:
            - path: /
              pathType: Prefix
              backend:
                service:
                  name: kube-prometheus-stack-grafana
                  port:
                    name: http-web
EOF
}


resource "kubectl_manifest" "application_dashboard" {
  depends_on = [
    module.charts_prometheus_operator
  ]

  yaml_body = <<-EOF
${file("${path.module}/../k8s/application-dashboard.yaml")}
EOF
}
