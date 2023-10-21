resource "helm_release" "application" {
  name      = "application"
  chart     = "${path.module}/helm/chart"
  namespace = "default"

  values = [<<-EOF
  deployment:
    replicaCount: 2
    image:
      repository: 273661173608.dkr.ecr.us-east-1.amazonaws.com/graylog-develop
      tag: develop
      pullPolicy: IfNotPresent
    resources:
      requests:
        cpu: 128m
        memory: 256Mi
      limits:
        cpu: 256m
        memory: 512Mi
    livenessProbe:
      initialDelaySeconds: 30
      periodSeconds: 10
      path: /healthz
    containerPort: 5000

  service:
    port: 5000
    type: ClusterIP
    annotations: {}

  # INGRESS
  ingress:
    enabled: true
    ingressClassName: alb
    annotations:
      kubernetes.io/ingress.global-static-ip-name: public-ip
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/target-type: ip
      # Health Check Settings
      alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
      alb.ingress.kubernetes.io/healthcheck-port: traffic-port
      #alb.ingress.kubernetes.io/tags: Name=${local.name}-application-ingress
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
            
    hosts:
      - host: ${local.domain_name}
        paths:
          - /
  EOF
  ]
}
