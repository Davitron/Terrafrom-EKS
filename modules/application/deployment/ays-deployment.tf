resource "kubernetes_deployment" "ays_server" {
  metadata {
      metadata {
    name      = "ays"
    namespace = "default"
    labels {
      app     = "ays"
    }
  }

    spec {
    replicas  = 2

    selector {
      match_labels {
        app         = "ays"
      }
    }

    template {
      metadata {
        namespace   = "default"
        labels {
          app       =  "ays"
        }
      }

      spec {
        container {
          image   = ""
          name    = "ays-server"
          port {
            container_port  = "3000"
            name            = "http"
          }
          image_pull_policy = "Always"
          liveness_probe {
            http_get {
              path  = "/"
              port  = "http"
            }
            initial_delay_seconds  = "10"
          }

        }
      }
    }
  }
}