variable "region" {
  description = "AWS region for LakeScout resources."
  type        = string
  default     = "us-east-2"
}

variable "alert_email" {
  description = "Address that receives budget notifications. Must be confirmed by email before alerts deliver."
  type        = string
}

variable "admin_user_name" {
  description = "IAM user that replaces the account root user for day-to-day provisioning."
  type        = string
  default     = "lakescout-admin"
}

variable "monthly_budget_usd" {
  description = "Hard ceiling for monthly spend. The deployment is designed to run at roughly $15-20."
  type        = number
  default     = 25
}
