# Python 3.12 slim (Debian trixie) 베이스 이미지 + OS 보안 패치 적용
FROM python:3.12-slim-trixie

# - apt-get update는 패키지 목록만 갱신하므로 실제 패치는 upgrade가 수행한다.
# - --error-on=any: 미러 접근 실패 시 경고만 내고 "0 upgraded"로 성공 처리되는 것을 막는다.
# - 마지막 검사: 업그레이드 가능 패키지가 남아 있으면 빌드 실패.
RUN apt-get update --error-on=any \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y --no-install-recommends \
    && test -z "$(apt list --upgradable 2>/dev/null | tail -n +2)" \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
