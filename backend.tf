# ==============================================================================
# 파일명: backend.tf
# 설명: Terraform Remote State (S3) 및 State Locking (DynamoDB) 원격 저장소 설정
# ==============================================================================

terraform {
  backend "s3" {
    bucket         = "cloudretail-gitops-dev-tfstate-2b12v9"
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "cloudretail-gitops-dev-tflocks"
    encrypt        = true
  }
}
