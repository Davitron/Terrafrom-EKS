resource "kubernetes_service" "ays_server" {
  metadata {
    name              = "ays"
    namespace         = "defualt"
  }

  spec {
    selector {
      app               = "{kubernetes_deployment.ays_server.metadata.0.labels.app}"
    }
    
    port {
        port            = "3000"
        target_port     = "http"
        name            = "http"
        protocol        = "TCP"
    }
    type              = "NodePort"
  }
}