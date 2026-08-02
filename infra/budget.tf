# The non-functional requirements call for a budget alarm to exist BEFORE the first
# deployment, so this is the first resource applied and it stands alone. Compute
# resources (EC2, Elastic IP, security group, SSM role) land in week 8.

resource "aws_budgets_budget" "monthly" {
  name         = "lakescout-monthly"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_usd
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "TagKeyValue"
    values = ["user:Project$lakescout"]
  }

  # Forecast warning: catches a runaway before the money is actually spent.
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }

  # Actual breach: the ceiling has been crossed for real.
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
}

# Untagged spend would slip past the filtered budget above, so a second unfiltered
# budget watches the whole account. Between them, nothing is invisible.
resource "aws_budgets_budget" "account_total" {
  name         = "lakescout-account-total"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_usd
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}
