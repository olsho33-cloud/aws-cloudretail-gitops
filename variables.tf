# ==============================================================================
# 파일명: variables.tf
# 설명: 프로젝트 전역 입력 변수 정의
# ==============================================================================

# [약속된 명령어] variable: 입력 변수 정의
variable "aws_region" {
  description = "AWS 배포 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "environment" {
  description = "배포 환경 (dev, stage, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "리소스 이름 접두어"
  type        = string
  default     = "cloudretail-gitops"
}
