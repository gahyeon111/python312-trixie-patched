#!/usr/bin/env bash
# [폐쇄망 Jupyter] tar 로드 → ECR 로그인 → 테스트 태그로 push
# 사용법: REPO=<베이스_리포지토리명> ./scripts/push-ecr.sh [tar 경로]
set -euo pipefail

TAR="${1:-python312-trixie-patched.tar}"
IMAGE="${IMAGE:-python312-trixie-patched:latest}"
REGION="${REGION:-ap-northeast-2}"
TAG="${TAG:-test-trixie-patched}"
: "${REPO:?REPO(ECR 리포지토리명)를 지정하세요}"

if [[ -f "$TAR.sha256" ]]; then
  echo "==> 체크섬 검증"
  sha256sum -c "$TAR.sha256"
fi

docker load -i "$TAR"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
ECR="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$ECR"

docker tag "$IMAGE" "$ECR/$REPO:$TAG"
docker push "$ECR/$REPO:$TAG"

echo "==> Push 완료: $ECR/$REPO:$TAG"
echo "    운영용 latest 태그는 검증 전까지 변경하지 마세요."
