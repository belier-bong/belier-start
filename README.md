# belier-start

BELIER 팀 워크플로우 라우터 스킬. Evan의 4단계(기획 → 스펙 → 개발·검증 → 유지)에 맞춰
알맞은 스킬을 자동으로 골라 쓰게 해준다. 부족한 스킬팩(gstack, superpowers, mattpocock, codex)은
첫 실행 시 자동 설치된다.

## 설치 (팀원용) — 30초

Claude Code 창에 아래 한 줄을 그대로 붙여넣으세요. 나머지는 Claude가 알아서 합니다.

```
belier-start 설치: git clone --depth 1 https://github.com/belier-bong/belier-start ~/.claude/skills/belier-start 를 실행한 다음 /belier-start 를 실행해줘
```

- 처음 `/belier-start`를 실행하면 부족한 도구(gstack·superpowers·mattpocock·codex)가 자동 설치됩니다.
- 마지막에 안내가 뜨면 터미널에서 `codex login`을 한 번만 하세요 (코드 리뷰를 쓸 경우만).

## 들어있는 것
- `SKILL.md` — 라우터 본체 (상황 판단 → 알맞은 스킬 자동 발동 → 보고)
- `setup.sh` — 4개 스킬팩 자동 설치 (idempotent)
- `CLAUDE.md` — 행동 수칙(Karpathy 4계명) + 스킬 라우팅 규칙. 프로젝트 폴더에 복사해 쓰면 좋다.

## 업데이트
최신으로 받으려면 다시:
```
cd ~/.claude/skills/belier-start && git pull
```
