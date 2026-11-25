# python312-trixie-patched

`python:3.12-slim-trixie`에 OS 보안 패치(`apt-get upgrade`)를 적용한 베이스 이미지를
외부망에서 빌드 → tar로 폐쇄망 반입 → ECR 업로드 → 스캔 확인하는 절차와 스크립트.

```
Dockerfile               패치 이미지 정의
scripts/build.sh         [외부망] 빌드 + 버전 확인 + tar/sha256 생성
scripts/push-ecr.sh      [폐쇄망 Jupyter] 체크섬 검증 + load + ECR push (테스트 태그)
scripts/scan-findings.sh ECR 스캔 결과(HIGH/CRITICAL) 요약
```

## 1. 외부 인터넷 환경에서 빌드 및 tar 생성

```bash
./scripts/build.sh                         # linux/amd64 (기본)
PLATFORM=linux/arm64 ./scripts/build.sh    # ECS가 ARM64(Graviton)인 경우
```

수행 내용:

1. `docker build --pull --no-cache` — 최신 `python:3.12-slim-trixie` 기반으로 매번 새로 빌드
2. `dpkg-query -W libc6 zlib1g`, `python --version` 출력
3. 업그레이드 가능 패키지가 남았는지 확인
4. `docker save` → `python312-trixie-patched.tar` + `.tar.sha256`

> **주의 — 조용한 패치 실패 방지**
> `apt-get update`는 미러 접근에 실패해도 경고(`W: Failed to fetch ...`)만 남기고 종료 코드 0으로 끝나며,
> 이어지는 `apt-get upgrade`는 `0 upgraded`로 "성공"합니다. 즉 **패치되지 않은 이미지가 정상 빌드된 것처럼 보일 수 있습니다.**
> 이 저장소의 Dockerfile은 `apt-get update --error-on=any`와 "업그레이드 가능 패키지 0개" 검사로 이런 경우 빌드를 실패시킵니다.
> 프록시 환경이면 `--build-arg http_proxy=... --build-arg https_proxy=...`를 전달하세요.

tar와 sha256 파일을 회사 승인 반입 경로로 폐쇄망 Jupyter에 전달합니다.

## 2. 폐쇄망 Jupyter에서 ECR 업로드

```bash
REPO=실제_베이스_리포지토리명 ./scripts/push-ecr.sh python312-trixie-patched.tar
# 선택: REGION(기본 ap-northeast-2), TAG(기본 test-trixie-patched)
```

`.tar.sha256`이 같은 위치에 있으면 load 전에 체크섬을 검증합니다.

## 3. ECR 취약점 검사 및 운영 반영

```bash
REPO=실제_베이스_리포지토리명 ./scripts/scan-findings.sh
```

- 테스트 태그 스캔 완료 후 HIGH/CRITICAL 취약점 확인.
- Debian에서 수정 패키지가 아직 제공되지 않은 CVE는 남을 수 있으므로 HIGH 0개는 보장되지 않습니다.
  (Debian Security Tracker에서 `no-DSA`/`<not-affected>`/미수정 여부 확인)
- 검증 전 운영용 `latest` 태그는 변경하지 않습니다.
- 검증 후 API/Batch 이미지를 새 베이스로 재빌드하고 ECS Fargate에서 호환성 테스트 후 배포합니다.
- 운영 반영 시 `latest` 대신 날짜 태그(예: `trixie-patched-20261125`)나 digest로 고정하면 롤백이 쉽습니다.

## 참고: AWS CloudShell

보안 정책상 허용되고 외부 인터넷 및 ECR 접근이 가능한 CloudShell에서 Docker 빌드가 가능하다면
tar 반입 없이 `build.sh` 후 바로 `push-ecr.sh`를 실행할 수 있습니다. Docker 저장 공간(약 1GB 홈 디렉터리 제한)과 IAM 권한을 확인하세요.
