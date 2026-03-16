# TOOLS.md - Local Notes

## Linear CLI

**항상 절대 경로 사용** (cron/heartbeat에서도 작동 보장):

```bash
export PATH=$HOME/.deno/bin:$PATH
~/.deno/bin/linear issue list --team SNA --sort priority --all-states -A
```

**주의**: `linear`만 입력하면 cron에서 실행되지 않을 수 있음

---

## ACP 사용 규칙

**코드 작업은 ACP Claude를 사용한다.**

```json
{
  "runtime": "acp",
  "agentId": "claude",
  "task": "작업 내용"
}
```

---

## ACP 프롬프트 작성 가이드

### 개선된 템플릿

```markdown
## [이슈 번호]: [제목] — TDD

### 프로젝트
- 경로: [프로젝트 경로]
- 브랜치: [브랜치명] (develop에서 생성)

### 문제
[구체적 문제 설명]

### 영향 파일
- [파일1] (구현)
- [파일2] (테스트)

### TDD 프로세스
1. Red: 테스트 먼저 작성
2. Green: 최소 코드로 통과
3. Refactor: 개선

### ⚠️ 검증 필수 (생략 금지)
```bash
# 전체 테스트 실행 (필수)
godot --headless --script addons/gut/gut_cmdln.gd --path . -gdir=test -gexit
```

### 완료 조건 (모두 충족해야 함)
- [ ] 전체 테스트: **0 failing**
- [ ] Format: `gdformat .` 통과
- [ ] Lint: `gdlint .` 통과
- [ ] Git: commit & push 완료
- [ ] PR 생성 완료
- [ ] Linear 상태: **In Review**로 변경

### PR 생성 후 필수
```bash
# PR 생성
gh pr create --base develop --title "[이슈 번호] 제목" --body "내용"

# Linear 상태 변경
linear issue update SNA-XXX --state "In Review"
```

### ❌ 실패 시
- 테스트 1개라도 실패하면 **commit 금지**
- 수정 불가능하면 즉시 중단하고 보고

### ⚠️ 진행 규칙
**질문하지 말고 바로 구현하세요. 승인 요청 없이 끝까지 완료하세요.**
```

### 핵심 원칙
1. **검증 명령어 명시** - "테스트 실행" 말고 실제 명령어
2. **완료 조건 체크리스트화** - 모두 충족해야 함
3. **실패 시 대응** - commit 금지, 중단 및 보고
4. **부분 테스트 금지** - 항상 전체 테스트 실행
5. **승인 질문 금지** - 계획 승인 요청 없이 바로 구현

### 프롬프트 필수 문구
모든 ACP 프롬프트에 추가:
```
**질문하지 말고 바로 구현하세요. 승인 요청 없이 끝까지 완료하세요.**
```

### SNA-174 반성
- ACP가 "BakeryManager 테스트만 실행" 하려다 전체 테스트 생략
- 결과: 41개 실패 상태로 커밋
- 교훈: 프롬프트에 구체적 명령어 + 실패 시 대응 명시

---

## Linear 이슈 상태 관리

### 워크플로우
```
Todo → In Progress → PR 생성 → In Review → PR merge → Done
```

### ❌ 절대 하지 말 것
- PR merge 전에 Done으로 변경
- 사용자 확인 없이 상태 변경

---

## Linear CLI

### 상태 매핑
| 표시 이름 | CLI 값 |
|---|---|
| Todo | `unstarted` |
| In Progress | `started` |
| Done | `completed` |

### Todo 이슈 조회
```bash
linear issue list --team SNA --state "unstarted" --sort priority --all-assignees
```

**주의**: `--all-assignees` 필수 (기본값: 내 이슈만)

---

Add whatever helps you do your job. This is your cheat sheet.
