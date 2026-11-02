locals {
  ecs_cluster = "default"
  ecs_service = "devops-eks2026-5fb1"
}

resource "aws_cloudwatch_dashboard" "wishifai" {
  dashboard_name = "Wishifai-29"

  dashboard_body = jsonencode({
    widgets = [
      # BUSINESS
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title   = "Business: gaveforslag generert"
          region  = var.aws_region
          view    = "timeSeries"
          stat    = "Sum"
          period  = 60
          metrics = [["Wishifai", "wishifai.suggestions.generated.count"]]
        }
      },
      # APPLIKASJON: egne latency-metrikker
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title  = "Applikasjon: Rekognition vs Bedrock latency (snitt)"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Average"
          period = 60
          metrics = [
            ["Wishifai", "wishifai.rekognition.latency.avg"],
            ["Wishifai", "wishifai.bedrock.latency.avg"]
          ]
        }
      },
      # INFRASTRUKTUR
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title  = "Infrastruktur: CPU og minne (ECS)"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Average"
          period = 60
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", local.ecs_cluster, "ServiceName", local.ecs_service],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", local.ecs_cluster, "ServiceName", local.ecs_service]
          ]
        }
      },
      # APPLIKASJON: Actuator
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title  = "Applikasjon: HTTP request-latency (max)"
          region = var.aws_region
          view   = "timeSeries"
          period = 60
          metrics = [
            [{
              expression = "SEARCH('Namespace=\"Wishifai\" MetricName=\"http.server.requests.max\"', 'Maximum', 60)"
              id         = "e1"
            }]
          ]
        }
      },
      {
        type = "metric", x = 0, y = 12, width = 12, height = 6
        properties = {
          title  = "Applikasjon: JVM-minne brukt"
          region = var.aws_region
          view   = "timeSeries"
          period = 60
          metrics = [
            [{
              expression = "SEARCH('Namespace=\"Wishifai\" MetricName=\"jvm.memory.used.value\"', 'Average', 60)"
              id         = "e2"
            }]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 12, width = 12, height = 6
        properties = {
          title  = "Applikasjon: GC-pausetid (maks)"
          region = var.aws_region
          view   = "timeSeries"
          period = 60
          metrics = [
            [{
              expression = "SEARCH('Namespace=\"Wishifai\" MetricName=\"jvm.gc.pause.max\"', 'Maximum', 60)"
              id         = "e3"
            }]
          ]
        }
      }
    ]
  })
}