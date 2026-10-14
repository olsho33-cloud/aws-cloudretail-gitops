# ==============================================================================
# 파일명: oidc_iam.tf
# 설명: GitHub Actions에서 AWS 영구 Access Key 없이 STS 임시 권한을 획득하기 위한 OIDC 설정
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. GitHub Repository 변수 선언
# ------------------------------------------------------------------------------
variable "github_repository" {
  description = "GitHub 계정/리포지토리명 (예: my-github-id/my-repo)"
  type        = string
  default     = "your-github-id/aws-cloudretail-gitops" # [★실무 핵심 수정 영역] 본인 GitHub ID/리포지토리명으로 변경 가능
}

# ------------------------------------------------------------------------------
# 2. GitHub OIDC Identity Provider 등록
# ------------------------------------------------------------------------------
# [약속된 명령어] resource "aws_iam_openid_connect_provider"
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  # GitHub OIDC 서버 지문(Thumbprint) 고정 값
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a21d81e5b274704812b1acd3140501386187"]
}

# ------------------------------------------------------------------------------
# 3. GitHub Actions 전용 IAM Role & Trust Policy (신뢰 관계)
# ------------------------------------------------------------------------------
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-${var.environment}-github-actions-role"

  # [★실무 핵심 보안] 지정한 GitHub Repository에서 오는 요청만 임시 권한(STS)을 받도록 신뢰 관계 정의
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
            # [★실무 핵심] 지정한 리포지토리의 제어 권한 부여
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:*"
          }
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# 4. IAM Policy 연결 (테라폼 인프라 제어를 위한 권한 부여)
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ------------------------------------------------------------------------------
# 5. Output 출력 (GitHub Secrets 설정 시 필요한 Role ARN)
# ------------------------------------------------------------------------------
output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "GitHub Actions 워크플로우에 등록할 IAM Role ARN 주소입니다."
}
