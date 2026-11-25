#!/usr/bin/env bash
# [외부 인터넷 환경] 패치 이미지 빌드 → 버전 확인 → tar 저장
# 사용법: PLATFORM=linux/arm64 ./scripts/build.sh   (기본 linux/amd64)
set -euo pipefail

PLATFORM="${PLATFORM:-linux/amd64}"
IMAGE="${IMAGE:-python312-trixie-patched:latest}"
TAR="${TAR:-python312-trixie-patched.tar}"
cd "$(dirname "$0")/.."

echo "==> Build ($PLATFORM): $IMAGE"
docker build --platform "$PLATFORM" --pull --no-cache -t "$IMAGE" .

echo "==> 주요 패키지 버전"
docker run --rm --platform "$PLATFORM" "$IMAGE" dpkg-query -W libc6 zlib1g
docker run --rm --platform "$PLATFORM" "$IMAGE" python --version

echo "==> 남은 업그레이드 가능 패키지 (비어 있어야 정상)"
docker run --rm --platform "$PLATFORM" "$IMAGE" \
  sh -c 'apt-get update -qq >/dev/null && apt list --upgradable 2>/dev/null | tail -n +2'

echo "==> Save: $TAR"
docker save -o "$TAR" "$IMAGE"
sha256sum "$TAR" | tee "$TAR.sha256"
echo "완료. $TAR 와 $TAR.sha256 을 승인된 반입 경로로 폐쇄망에 전달하세요."
