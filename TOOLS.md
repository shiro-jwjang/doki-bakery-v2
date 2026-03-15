# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## ACP 프롬프트 작성 가이드

### ❌ 나쁜 프롬프트
```
테스트 실패 3개 수정해줘
```

### ✅ 좋은 프롬프트
```
## 테스트 실패 1개 수정

### 실패 정보
- 파일: test/example.gd
- 테스트: test_something
- 에러: "Expected X but got Y"

### 관련 파일
- scripts/example.gd (구현)
- test/test_example.gd (테스트)

### 문제 분석
(구체적인 원인)

### 해결 방법
1. (구체적 단계)

### 완료 조건
- 테스트 0개 실패
- git commit & push 완료
```

### 핵심 원칙
1. **구체적 에러 메시지** - "실패" 말고 실제 에러 텍스트
2. **파일 경로** - 어디를 수정할지 명시
3. **컨텍스트** - 프로젝트 구조/의존성 설명
4. **완료 조건** - 언제 끝났는지 명확한 기준
5. **검증 방법** - 어떻게 확인할지

### 참고: SNA-183 반성
- 31개 → 0개 실패로 줄였지만 구체적 정보 없이 시작해서 시간 낭비
- "safe_update should execute callable" 에러를 미리 줬으면 더 빨랐을 것

---

## Linear 이슈 상태 관리

### 워크플로우
```
Todo → In Progress → PR 생성 → In Review → PR merge → Done
```

### 상태별 액션
| 상태 | 액션 | 언제 |
|---|---|---|
| Todo | 작업 시작 안 함 | 이슈 생성 시 |
| In Progress | 작업 중 | 코드 작성 시작 |
| In Review | PR 생성 후 | PR merge 대기 |
| Done | PR merge 완료 | 모든 리뷰 통과 |

### ❌ 절대 하지 말 것
- PR merge 전에 Done으로 변경
- 사용자 확인 없이 상태 변경
- "이슈 처리는?" 질문에 성급하게 Done 처리

### 참고: SNA-183 반성
- PR 생성 후 바로 Done으로 변경함 (잘못됨)
- 올바른 흐름: PR 생성 → In Review → merge → Done

---

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.
