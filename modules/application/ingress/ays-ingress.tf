resource "kubernetes_ingress" "ays_ingress" {
  metadata {
    name = "ays-ingress"
    namespace = "default"
  }

  spec {
    rule {
      http {
        path {
          backend {
            service_name = "ays"
            service_port = 3000
          }

          path = "/"
        }
      }
    }
  }
}