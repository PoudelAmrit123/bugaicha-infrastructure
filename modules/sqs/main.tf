resource "aws_sqs_queue" "this" {
  name                       = var.name
  delay_seconds              = var.delay_seconds
  max_message_size           = var.max_message_size
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds

  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.content_based_deduplication

  redrive_policy = var.create_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null

  tags = var.tags
}


resource "aws_sqs_queue" "dlq" {
  count = var.create_dlq ? 1 : 0

  name                      = "${var.name}-dlq"
  message_retention_seconds = var.dlq_message_retention_seconds
  fifo_queue                = var.fifo_queue

  tags = var.tags
}