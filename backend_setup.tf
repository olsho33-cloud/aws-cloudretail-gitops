# ==============================================================================
# 파일명: backend_setup.tf
# 설명: Remote State 저장용 S3 버킷 및 Lock 관리용 DynamoDB 테이블 생성
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. S3 버킷 고유 이름 지정을 위한 난수 생성
# ------------------------------------------------------------------------------
# [약속된 명령어] resource "random_string"
resource "random_string" "tf_suffix" {
  length  = 6
  special = false
  upper   = false
}

# ------------------------------------------------------------------------------
# 2. Terraform Remote State 저장용 S3 버킷
# ------------------------------------------------------------------------------
# [약속된 명령어] resource "aws_s3_bucket"
resource "aws_s3_bucket" "tf_state" {
  # [임의 지정/변수 조합] 전 세계 유일한 S3 버킷명 생성
  bucket        = "${var.project_name}-${var.environment}-tfstate-${random_string.tf_suffix.result}"
  force_destroy = true # 실습 후 terraform destroy 시 버킷 내 파일 일괄 삭제

  tags = {
    Name = "${var.project_name}-${var.environment}-tfstate"
  }
}

# [★실무 핵심] State 파일 변경 이력 관리를 위한 버킷 버저닝(Versioning) 활성화
resource "aws_s3_bucket_versioning" "tf_state_ver" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# [★실무 핵심] State 파일 내부의 민감 정보 보호를 위한 S3 암호화(KMS/AES256) 적용
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_enc" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# [★실무 핵심 보안] 외부 인터넷 직접 접근 100% 차단
resource "aws_s3_bucket_public_access_block" "tf_state_pab" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# 3. Terraform State Locking 전용 DynamoDB 테이블
# ------------------------------------------------------------------------------
# [약속된 명령어] resource "aws_dynamodb_table"
resource "aws_dynamodb_table" "tf_locks" {
  name         = "${var.project_name}-${var.environment}-tflocks"
  billing_mode = "PAY_PER_REQUEST" # [★실무 핵심] 트래픽 기반 유연한 과금 방식

  # [★약속된 필수 키] 테라폼 백엔드가 State Lock 관리에 사용하는 기본 키 명칭은 LockID
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-tflocks"
  }
}

# ------------------------------------------------------------------------------
# 4. Output 선언 (생성된 S3 버킷명 및 DynamoDB 테이블명)
# ------------------------------------------------------------------------------
output "s3_bucket_name" {
  value       = aws_s3_bucket.tf_state.bucket
  description = "Remote State가 저장될 S3 버킷 이름입니다."
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.tf_locks.name
  description = "State Locking에 사용될 DynamoDB 테이블 이름입니다."
}
