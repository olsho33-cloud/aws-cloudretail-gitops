# ==============================================================================
# 파일명: oidc_iam.tf
# 설명: GitHub Actions에서 AWS 영구 Access Key 없이 STS 임시 권한을 획득하기 위한 OIDC 설정
# ==============================================================================

variable "github_repository" {
  description = "GitHub 계정/리포지토리명"
  type        = string
  # [수정 완료] 실제 GitHub 계정명/리포지토리명 적용
  default     = "olsho33-cloud/aws-cloudretail-gitops"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a21d81e5b274704812b1acd3140501386187"]
}

resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-${var.environment}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "GitHub Actions 워크플로우에 등록할 IAM Role ARN 주소입니다."
}
