# ==============================================================================
# 파일명: provider.tf
# 설명: 테라폼 프로바이더 정의 및 AWS 리전, 공통 태그 설정
# ==============================================================================

# [약속된 명령어] terraform 블록: CLI 버전 및 프로바이더 요구사항 정의
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# [약속된 명령어] provider "aws": AWS 리전 및 공통 태그 부여
provider "aws" {
  # [임의 지정/변수 참조] 서울 리전 지정
  region = var.aws_region

  # [약속된 명령어] default_tags: 생성되는 모든 리소스에 관리 태그 삽입
  default_tags {
    tags = {
      Project     = "CloudRetail-GitOps"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
