#!/usr/bin/env bash
# ==========================================
# GitOps pull-deploy
# - 원격 브랜치에 새 커밋이 있을 때만 pull -> 빌드 -> ROOT.war 교체 -> Tomcat 재시작
# - 외부 설정(/opt/app/config)은 절대 건드리지 않는다
# ==========================================
set -euo pipefail

# 빌드 환경(브랜치/경로)은 /etc/gitops/env 에서 읽는다
# shellcheck disable=SC1091
[ -f /etc/gitops/env ] && . /etc/gitops/env
REPO_DIR="${REPO_DIR:-/opt/app/src}"
BRANCH="${APP_BRANCH:-main}"
CATALINA_HOME="${CATALINA_HOME:-/opt/tomcat/tomcat-10}"
LOG="/var/log/gitops-deploy.log"
FORCE="${1:-}"

exec >>"$LOG" 2>&1
echo "=== $(date -Is) gitops check (branch=$BRANCH force=$FORCE) ==="

# systemd 환경엔 $HOME 이 없어서 git 이 'fatal: $HOME not set' 으로 깨진다 -> 명시
export HOME="${HOME:-/root}"

cd "$REPO_DIR"
# safe.directory 는 베이크 때 'git config --system' 으로 이미 등록됨(HOME 불필요)
git fetch --quiet origin "$BRANCH"

LOCAL="$(git rev-parse HEAD)"
REMOTE="$(git rev-parse "origin/$BRANCH")"

if [ "$LOCAL" = "$REMOTE" ] && [ "$FORCE" != "--force" ]; then
  echo "already up to date ($LOCAL) - skip"
  exit 0
fi

echo "deploying $LOCAL -> $REMOTE"
git reset --hard "origin/$BRANCH"

mvn -q clean package -DskipTests

WAR="$(ls -1 target/*.war 2>/dev/null | grep -v '\.original$' | head -n1)"
if [ -z "$WAR" ]; then
  echo "ERROR: build produced no WAR"
  exit 1
fi

# Tomcat autoDeploy 가 ROOT.war 를 자동으로 풀어 배포한다 (수동 jar -xf 불필요)
rm -rf "$CATALINA_HOME/webapps/ROOT" "$CATALINA_HOME/webapps/ROOT.war"
cp "$WAR" "$CATALINA_HOME/webapps/ROOT.war"
chown -R tomcat:tomcat "$CATALINA_HOME/webapps"

systemctl restart tomcat
echo "deployed $REMOTE OK"
