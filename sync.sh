#!/usr/bin/env bash
# belier-start sync — 개인 프로젝트 모노레포(~/Desktop/프로젝트)를 GitHub와 동기화한다.
# 비개발자 보호: force-push 안 함, 충돌 시 자동병합 안 하고 멈춰서 안내.
# 사용법:
#   bash sync.sh 받기    # = pull (다른 컴퓨터 작업 가져오기)
#   bash sync.sh 저장    # = commit + push (이 컴퓨터 작업 올리기)
set -uo pipefail

PROJ="$HOME/Desktop/프로젝트"
MODE="${1:-}"

if [ ! -d "$PROJ/.git" ]; then
  echo "⚠ 아직 동기화 저장소가 없어요. 새 컴퓨터면 먼저 받아오세요:"
  echo "    git clone https://github.com/belier-bong/belier-projects \"$PROJ\""
  exit 1
fi

cd "$PROJ" || exit 1
# 커밋용 신원 (없으면 설정)
git config user.name  >/dev/null 2>&1 || git config user.name  "belier-bong"
git config user.email >/dev/null 2>&1 || git config user.email "beliermaking@gmail.com"

case "$MODE" in
  받기|pull)
    echo "▶ 다른 컴퓨터에서 한 작업을 가져옵니다..."
    if git pull --no-rebase 2>&1 | grep -qi "conflict"; then
      echo "⚠ 같은 파일이 양쪽 컴퓨터에서 바뀌어 충돌했어요."
      echo "   어느 내용을 살릴지 정해야 합니다. 충돌 파일:"
      git diff --name-only --diff-filter=U | sed 's/^/     - /'
      echo "   → 이 화면을 담당자(또는 Claude)에게 보여주세요. 강제로 덮어쓰지 않았습니다."
      exit 2
    fi
    echo "✓ 받기 완료. 최신 상태로 이어서 작업하면 됩니다."
    ;;

  저장|push)
    echo "▶ 이 컴퓨터의 작업을 올립니다..."
    if [ -z "$(git status --porcelain)" ]; then
      echo "  · 바뀐 게 없어요. 올릴 것 없음."
    else
      git add -A
      git commit -q -m "작업 저장: $(date '+%Y-%m-%d %H:%M')"
      echo "  · 저장본 생성"
    fi
    # push 시도. 거절되면(다른 컴퓨터가 먼저 올림) 받기 후 재시도.
    if ! git push -q 2>/dev/null; then
      echo "  · 다른 컴퓨터에서 먼저 올린 작업이 있어요. 받기부터 할게요..."
      if git pull --no-rebase 2>&1 | grep -qi "conflict"; then
        echo "⚠ 충돌 발생. 같은 파일이 양쪽에서 바뀌었어요:"
        git diff --name-only --diff-filter=U | sed 's/^/     - /'
        echo "   → 이 화면을 담당자(또는 Claude)에게 보여주세요. 강제로 덮어쓰지 않았습니다."
        exit 2
      fi
      git push -q 2>/dev/null && echo "✓ 저장 완료 (받기 후 다시 올림)." || {
        echo "⚠ 올리기 실패. 인터넷/권한을 확인하거나 담당자에게 문의하세요."
        exit 1
      }
    else
      echo "✓ 저장 완료. 이제 다른 컴퓨터에서 '받기' 하면 그대로 이어집니다."
    fi
    ;;

  *)
    echo "사용법: bash sync.sh 받기   (다른 컴퓨터 작업 가져오기)"
    echo "        bash sync.sh 저장   (이 컴퓨터 작업 올리기)"
    exit 1
    ;;
esac
