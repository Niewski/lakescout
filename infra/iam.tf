# Replaces day-to-day use of the account root user.
#
# No access key is created here on purpose. The CLI authenticates with `aws login`,
# which federates from a console sign-in and issues short-lived credentials, so no
# long-lived secret exists to leak, rotate, or land in terraform.tfstate.
#
# The console password is NOT set by Terraform either: aws_iam_user_login_profile
# stores the initial password in state in plaintext, which defeats the point. Set it
# once in the console instead (see infra/README.md).

resource "aws_iam_user" "admin" {
  name = var.admin_user_name
  path = "/lakescout/"

  # Refuse to delete a user that still has keys or policies attached, so a stray
  # `terraform destroy` cannot quietly remove an identity that something depends on.
  force_destroy = false
}

resource "aws_iam_group" "admins" {
  name = "lakescout-admins"
  path = "/lakescout/"
}

resource "aws_iam_user_group_membership" "admin" {
  user   = aws_iam_user.admin.name
  groups = [aws_iam_group.admins.name]
}

# Permissions are attached to the group, not the user, so a second operator can be
# added later without duplicating policy wiring.
resource "aws_iam_group_policy_attachment" "admin" {
  group      = aws_iam_group.admins.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Full admin is only useful if a stolen password alone cannot use it. This policy
# denies every action unless the caller authenticated with MFA, while carving out
# exactly the actions needed to enrol an MFA device in the first place. Without that
# carve-out a brand new user is locked out of bootstrapping their own MFA.
resource "aws_iam_policy" "require_mfa" {
  name        = "lakescout-require-mfa"
  path        = "/lakescout/"
  description = "Denies all actions unless the session is MFA authenticated, except those needed to enrol an MFA device."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowViewAccountInfo"
        Effect = "Allow"
        Action = [
          "iam:GetAccountPasswordPolicy",
          "iam:ListVirtualMFADevices",
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowManageOwnPassword"
        Effect = "Allow"
        Action = [
          "iam:ChangePassword",
          "iam:GetUser",
        ]
        # $${} escapes Terraform interpolation so the literal IAM policy variable
        # ${aws:username} reaches AWS and resolves per-caller.
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      },
      {
        Sid      = "AllowCreateOwnVirtualMFADevice"
        Effect   = "Allow"
        Action   = ["iam:CreateVirtualMFADevice"]
        Resource = "arn:aws:iam::*:mfa/*"
      },
      {
        Sid    = "AllowManageOwnMFADevice"
        Effect = "Allow"
        Action = [
          "iam:DeactivateMFADevice",
          "iam:EnableMFADevice",
          "iam:ListMFADevices",
          "iam:ResyncMFADevice",
        ]
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      },
      {
        Sid    = "DenyEverythingElseWithoutMFA"
        Effect = "Deny"
        NotAction = [
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:GetUser",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:ResyncMFADevice",
          "iam:ChangePassword",
          "iam:GetAccountPasswordPolicy",
          "sts:GetSessionToken",
        ]
        Resource = "*"
        Condition = {
          # BoolIfExists, not Bool: for requests where aws:MultiFactorAuthPresent is
          # absent entirely, a plain Bool comparison does not match and the deny
          # silently fails to apply.
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      },
    ]
  })
}

resource "aws_iam_group_policy_attachment" "require_mfa" {
  group      = aws_iam_group.admins.name
  policy_arn = aws_iam_policy.require_mfa.arn
}

# A weak console password would undercut everything above, since the password is the
# only factor Terraform does not control.
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 16
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 180
  password_reuse_prevention      = 5
}
