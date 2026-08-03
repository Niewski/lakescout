output "console_sign_in_url" {
  description = "IAM sign-in page for this account. The admin user signs in here, not through the root email form."
  value       = "https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console"
}

output "admin_user_arn" {
  description = "ARN of the LakeScout admin user."
  value       = aws_iam_user.admin.arn
}

output "next_steps" {
  description = "Manual steps Terraform deliberately does not perform, because doing so would write a secret into state."
  value       = <<-EOT
    1. As root, open IAM > Users > ${aws_iam_user.admin.name} > Security credentials.
    2. Enable console access and set a password (16+ chars, mixed case, number, symbol).
    3. Sign out of root. Sign in at the console_sign_in_url above as ${aws_iam_user.admin.name}.
    4. Assign an MFA device. Until MFA is assigned this user can do almost nothing,
       which is the require-mfa policy working as intended.
    5. Run: aws login --region ${var.region}
    6. Confirm with: aws sts get-caller-identity
       The Arn should end in user/lakescout/${aws_iam_user.admin.name}, not :root.
    7. Enable MFA on the root user too, then stop using it.
  EOT
}
