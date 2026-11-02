variable "alarm_email" {
  type        = string
  description = "E-post som mottar alarmvarsler"
}

resource "aws_sns_topic" "alerts" {
  name = "wishifai-alerts-29"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_cloudwatch_metric_alarm" "bedrock_slow" {
  alarm_name          = "wishifai-bedrock-latency-high-29"
  alarm_description   = "Bedrock-kall er tregere enn 8 sekunder i snitt over 2 perioder"
  namespace           = "Wishifai"
  metric_name         = "wishifai.bedrock.latency.avg"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 8000
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}