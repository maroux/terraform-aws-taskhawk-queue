module "queue_default" {
  source = "./modules/queue"

  queue = "${var.queue}"

  max_receive_count = "${var.max_receive_count}"
  alerting          = "${var.alerting}"
  tags              = "${var.tags}"

  queue_alarm_high_message_count_threshold = "${var.queue_alarm_high_message_count_threshold}"
  queue_ok_high_message_count_actions      = "${var.queue_ok_high_message_count_actions}"
  queue_alarm_high_message_count_actions   = "${var.queue_alarm_high_message_count_actions}"
  dlq_ok_high_message_count_actions        = "${var.dlq_ok_high_message_count_actions}"
  dlq_alarm_high_message_count_actions     = "${var.dlq_alarm_high_message_count_actions}"
}

module "queue_high_priority" {
  source = "./modules/queue"

  queue = "${var.queue}-HIGH-PRIORITY"

  max_receive_count = "${var.max_receive_count}"
  alerting          = "${var.alerting}"
  tags              = "${var.tags}"

  queue_alarm_high_message_count_threshold = "${var.queue_alarm_high_priority_high_message_count_threshold}"
  queue_ok_high_message_count_actions      = "${var.queue_ok_high_message_count_actions}"
  queue_alarm_high_message_count_actions   = "${var.queue_alarm_high_message_count_actions}"
  dlq_ok_high_message_count_actions        = "${var.dlq_ok_high_message_count_actions}"
  dlq_alarm_high_message_count_actions     = "${var.dlq_alarm_high_message_count_actions}"
}

module "queue_low_priority" {
  source = "./modules/queue"

  queue = "${var.queue}-LOW-PRIORITY"

  max_receive_count = "${var.max_receive_count}"
  alerting          = "${var.alerting}"
  tags              = "${var.tags}"

  queue_alarm_high_message_count_threshold = "${var.queue_alarm_low_priority_high_message_count_threshold}"
  queue_ok_high_message_count_actions      = "${var.queue_ok_high_message_count_actions}"
  queue_alarm_high_message_count_actions   = "${var.queue_alarm_high_message_count_actions}"
  dlq_ok_high_message_count_actions        = "${var.dlq_ok_high_message_count_actions}"
  dlq_alarm_high_message_count_actions     = "${var.dlq_alarm_high_message_count_actions}"
}

module "queue_bulk" {
  source = "./modules/queue"

  queue = "${var.queue}-BULK"

  max_receive_count = "${var.max_receive_count}"
  alerting          = "${var.alerting}"
  tags              = "${var.tags}"

  queue_alarm_high_message_count_threshold = "${var.queue_alarm_bulk_high_message_count_threshold}"
  queue_ok_high_message_count_actions      = "${var.queue_ok_high_message_count_actions}"
  queue_alarm_high_message_count_actions   = "${var.queue_alarm_high_message_count_actions}"
  dlq_ok_high_message_count_actions        = "${var.dlq_ok_high_message_count_actions}"
  dlq_alarm_high_message_count_actions     = "${var.dlq_alarm_high_message_count_actions}"
}

data "aws_iam_policy_document" "policy_document" {
  "statement" {
    actions = [
      "sqs:*",
    ]

    resources = [
      "${module.queue_default.sqs_queue_arn}",
      "${module.queue_default.dlq_arn}",
      "${module.queue_high_priority.sqs_queue_arn}",
      "${module.queue_high_priority.dlq_arn}",
      "${module.queue_low_priority.sqs_queue_arn}",
      "${module.queue_low_priority.dlq_arn}",
      "${module.queue_bulk.sqs_queue_arn}",
      "${module.queue_bulk.dlq_arn}",
    ]
  }
}

resource "aws_iam_policy" "policy" {
  count = "${var.iam == "true" ? 1 : 0}"

  name        = "taskhawk-${var.queue}"
  description = "Taskhawk policy for ${var.queue}"

  policy = "${data.aws_iam_policy_document.policy_document.json}"
}

data "aws_iam_policy_document" "scheduler_policy_document" {
  "statement" {
    sid = "AllowCloudwatchRule"

    actions = [
      "sqs:SendMessage",
    ]

    resources = [
      "${module.queue_default.sqs_queue_arn}",
    ]

    principals {
      identifiers = [
        "events.amazonaws.com",
      ]

      type = "Service"
    }

    condition {
      test = "ArnEquals"

      # use lower case by default since tf-generator would change case when creating rule name
      values = [
        "arn:aws:events:${var.aws_region}:${var.aws_account_id}:rule/taskhawk-${lower(var.queue)}-*",
      ]

      variable = "aws:SourceArn"
    }
  }
}

resource "aws_sqs_queue_policy" "default_queue_policy" {
  count = "${var.iam && var.enable_scheduler ? 1 : 0}"

  policy    = "${data.aws_iam_policy_document.scheduler_policy_document.json}"
  queue_url = "${module.queue_default.sqs_queue_url}"
}
