#!/usr/bin/env bash
# ECR 스캔 완료 대기 후 HIGH/CRITICAL 결과 요약
# 사용법: REPO=<리포지토리명> ./scripts/scan-findings.sh
set -euo pipefail

REGION="${REGION:-ap-northeast-2}"
TAG="${TAG:-test-trixie-patched}"
: "${REPO:?REPO(ECR 리포지토리명)를 지정하세요}"

echo "==> 스캔 완료 대기 (basic scanning 기준)"
aws ecr wait image-scan-complete --region "$REGION" \
  --repository-name "$REPO" --image-id imageTag="$TAG" || true

aws ecr describe-image-scan-findings --region "$REGION" \
  --repository-name "$REPO" --image-id imageTag="$TAG" \
  --query 'imageScanFindings.findingSeverityCounts' --output table

aws ecr describe-image-scan-findings --region "$REGION" \
  --repository-name "$REPO" --image-id imageTag="$TAG" \
  --query "imageScanFindings.findings[?severity=='HIGH'||severity=='CRITICAL'].[severity,name,attributes[?key=='package_name']|[0].value]" \
  --output table
