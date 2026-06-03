#!/usr/bin/env bash
# belier-start setup — Evan 4단계 워크플로우에 필요한 스킬팩 4종을 idempotent하게 설치한다.
#   gstack · superpowers · mattpocock(2) · codex
# 사용법:
#   bash setup.sh           # 설치 (이미 있으면 건너뜀)
#   bash setup.sh --check   # 설치 상태만 출력 (설치 안 함)
set -uo pipefail

SKILLS_DIR="$HOME/.claude/skills"
GSTACK_REPO="https://github.com/garrytan/gstack.git"
SP_MARKET="obra/superpowers-marketplace"
SP_PLUGIN="superpowers@superpowers-marketplace"
MATT_REPO="https://github.com/mattpocock/skills"
MATT_SKILLS=("grill-with-docs" "improve-codebase-architecture")  # repo의 skills/engineering/ 아래
CHECK_ONLY="no"
[ "${1:-}" = "--check" ] && CHECK_ONLY="yes"

have_cmd() { command -v "$1" >/dev/null 2>&1; }
have_gstack()      { [ -d "$SKILLS_DIR/gstack/office-hours" ] || [ -d "$SKILLS_DIR/office-hours" ]; }
have_superpowers() { find "$HOME/.claude/plugins" -maxdepth 6 -type d -name "brainstorming" 2>/dev/null | grep -q . ; }
have_matt()        { [ -d "$SKILLS_DIR/$1" ]; }
have_codex()       { have_cmd codex; }

# =====================  --check 모드  =====================
if [ "$CHECK_ONLY" = "yes" ]; then
  have_gstack      && echo "OK: gstack"      || echo "MISSING: gstack"
  have_superpowers && echo "OK: superpowers" || echo "MISSING: superpowers"
  for s in "${MATT_SKILLS[@]}"; do
    have_matt "$s" && echo "OK: $s" || echo "MISSING: $s"
  done
  if have_codex; then
    echo "OK: codex"
    echo "CODEX_AUTH: unknown (codex login 여부는 자동 확인 불가 — Phase 3 전 직접 로그인 권장)"
  else
    echo "MISSING: codex"
    echo "CODEX_AUTH: no"
  fi
  exit 0
fi

# =====================  설치 모드  =====================
echo "▶ belier-start 설치 시작..."
mkdir -p "$SKILLS_DIR"
MANUAL_STEPS=()   # 자동으로 못 한 단계를 모아 끝에 안내

# 공통 사전 도구
have_cmd git || MANUAL_STEPS+=("git 설치 필요: https://git-scm.com")
have_cmd npm || MANUAL_STEPS+=("npm(Node.js) 설치 필요: https://nodejs.org")

# --- 1) gstack (git clone + ./setup, bun 필요) ---
if have_gstack; then
  echo "  · gstack 이미 설치됨, 건너뜀"
else
  echo "  · gstack 설치 중..."
  if ! have_cmd git; then
    echo "    ⚠ git이 없어 건너뜀."
  elif ! have_cmd bun; then
    echo "    ⚠ gstack 빌드에 'bun'이 필요한데 없습니다. 아래 한 줄을 직접 실행 후 다시 setup 하세요:"
    echo "        curl -fsSL https://bun.sh/install | bash"
    MANUAL_STEPS+=("bun 설치 후: git clone --single-branch --depth 1 $GSTACK_REPO ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup")
  else
    if git clone --single-branch --depth 1 "$GSTACK_REPO" "$SKILLS_DIR/gstack" >/dev/null 2>&1; then
      ( cd "$SKILLS_DIR/gstack" && ./setup ) && echo "    ✓ gstack 설치됨" || {
        echo "    ⚠ gstack ./setup 실패. 수동: cd ~/.claude/skills/gstack && ./setup"
        MANUAL_STEPS+=("cd ~/.claude/skills/gstack && ./setup")
      }
    else
      echo "    ⚠ gstack 클론 실패 (네트워크/이미 존재)."
    fi
  fi
fi

# --- 2) superpowers (Claude Code 플러그인) ---
if have_superpowers; then
  echo "  · superpowers 이미 설치됨, 건너뜀"
else
  echo "  · superpowers 설치 중 (Claude Code 플러그인)..."
  if have_cmd claude; then
    claude plugin marketplace add "$SP_MARKET" >/dev/null 2>&1
    if claude plugin install "$SP_PLUGIN" >/dev/null 2>&1; then
      echo "    ✓ superpowers 설치됨"
    else
      echo "    ⚠ 자동 설치 실패. Claude Code에서 직접 두 줄 실행하세요:"
      echo "        /plugin marketplace add $SP_MARKET"
      echo "        /plugin install $SP_PLUGIN"
      MANUAL_STEPS+=("Claude Code: /plugin marketplace add $SP_MARKET → /plugin install $SP_PLUGIN")
    fi
  else
    echo "    ⚠ 'claude' CLI를 못 찾음. Claude Code에서 직접 두 줄 실행하세요:"
    echo "        /plugin marketplace add $SP_MARKET"
    echo "        /plugin install $SP_PLUGIN"
    MANUAL_STEPS+=("Claude Code: /plugin marketplace add $SP_MARKET → /plugin install $SP_PLUGIN")
  fi
fi

# --- 3) mattpocock 스킬 2개 ---
NEED_MATT="no"
for s in "${MATT_SKILLS[@]}"; do have_matt "$s" || NEED_MATT="yes"; done
if [ "$NEED_MATT" = "yes" ] && have_cmd git; then
  echo "  · mattpocock 스킬 설치 중 (grill-with-docs, improve-codebase-architecture)..."
  TMP="$(mktemp -d)"
  if git clone --depth 1 "$MATT_REPO" "$TMP/skills" >/dev/null 2>&1; then
    for s in "${MATT_SKILLS[@]}"; do
      SRC="$TMP/skills/skills/engineering/$s"
      if [ -d "$SRC" ] && ! have_matt "$s"; then
        cp -R "$SRC" "$SKILLS_DIR/$s" && echo "    ✓ $s 설치됨"
      elif have_matt "$s"; then
        echo "    - $s 이미 있음, 건너뜀"
      else
        echo "    ⚠ $s 를 repo에서 못 찾음 (구조 변경 가능): $MATT_REPO"
      fi
    done
  else
    echo "    ⚠ mattpocock repo 클론 실패."
    MANUAL_STEPS+=("$MATT_REPO 의 skills/engineering/ 아래 두 폴더를 ~/.claude/skills/ 로 복사")
  fi
  rm -rf "$TMP"
elif [ "$NEED_MATT" = "no" ]; then
  echo "  · mattpocock 스킬 이미 설치됨, 건너뜀"
fi

# --- 4) codex CLI ---
if have_codex; then
  echo "  · codex 이미 설치됨, 건너뜀"
elif ! have_cmd npm; then
  echo "  · codex 설치 건너뜀 (npm 없음)"
else
  echo "  · codex 설치 중 (npm i -g @openai/codex)..."
  PREFIX="$(npm config get prefix 2>/dev/null)"
  if [ -n "$PREFIX" ] && { [ -w "$PREFIX/lib/node_modules" ] 2>/dev/null || [ -w "$PREFIX/lib" ] 2>/dev/null || [ -w "$PREFIX" ] 2>/dev/null; }; then
    npm install -g @openai/codex >/dev/null 2>&1 && echo "    ✓ codex 설치됨" || {
      echo "    ⚠ codex 설치 실패. 수동: npm install -g @openai/codex"
      MANUAL_STEPS+=("npm install -g @openai/codex")
    }
  else
    echo "    ⚠ npm 글로벌 설치에 관리자 권한이 필요해 보입니다. 아래를 직접 실행하세요:"
    echo "        npm config set prefix ~/.npm-global   # 1회 설정"
    echo "        npm install -g @openai/codex"
    MANUAL_STEPS+=("npm config set prefix ~/.npm-global 후 npm install -g @openai/codex")
  fi
fi

# --- 마무리 안내 ---
echo ""
echo "▶ 설치 끝."
if [ "${#MANUAL_STEPS[@]}" -gt 0 ]; then
  echo "⚠ 자동으로 못 한 단계 (직접 해주세요):"
  for step in "${MANUAL_STEPS[@]}"; do echo "   • $step"; done
  echo ""
fi
echo "마지막 1회 수동 단계:"
echo "  · codex 코드 리뷰를 쓰려면 터미널에서 한 번:  codex login  (안 쓰면 생략 가능)"
echo "✓ belier-start 준비 완료. 'bash setup.sh --check' 로 상태를 다시 확인할 수 있어요."
