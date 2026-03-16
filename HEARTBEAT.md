# HEARTBEAT.md — builder

## 체크 (매 회)

### 0. Worktree 정리 (선택)

완료된 PR의 worktree를 정리한다.

```bash
# 완료된 worktree 확인
git worktree list

# PR이 머지된 worktree 삭제
./scripts/worktree.sh remove SNA-XXX
```

### 1. 빌더 ACP 세션 상태 확인

**빌더가 시작한 ACP 세션만** 추적한다.

```bash
# 활성 세션 파일 확인
cat memory/active-acp-sessions.json 2>/dev/null || echo "{}"
```

빌더가 `sessions_spawn`으로 ACP를 시작할 때 `memory/active-acp-sessions.json`에 세션 ID를 기록한다.

### 2. 상태별 액션

| 상태 | 액션 |
|------|------|
| **완료** | 목표 달성 확인 → 미달성 시 재시도 |
| **진행 중** | 상태 요약 |
| **실패/중단** | **재시도** |

### 3. 완료 세션 목표 확인

완료된 세션은 목표 달성 여부를 확인한다:

1. `sessions_history(sessionKey)`로 세션 내용 조회
2. 마지막 메시지에서 목표 달성 여부 판단
3. **미달성**으로 판단되면 재시도

판단 기준:
- "완료", "done", "success" → 달성
- "실패", "error", "incomplete", "could not" → 미달성
- 명확하지 않으면 미달성으로 간주

### 4. 세션 기록 관리

**ACP 시작 시**: 세션 ID를 `memory/active-acp-sessions.json`에 추가

**ACP 완료 시**: 세션 ID를 파일에서 제거

```json
// memory/active-acp-sessions.json 예시
{
  "sessions": {
    "agent:claude:acp:xxx": {"issue": "SNA-168", "started": "2026-03-16T00:00:00Z"},
    "agent:claude:acp:yyy": {"issue": "SNA-185", "started": "2026-03-16T07:00:00Z"}
  }
}
```

### 5. 재시도 규칙

실패/중단된 ACP 세션 발견 시:

1. `sessions_spawn`으로 **세션 재개**
2. `resumeSessionId` 사용해서 컨텍스트 유지

```json
{
  "runtime": "acp",
  "agentId": "<원래 agentId>",
  "resumeSessionId": "<중단된 세션 ID>",
  "task": "Continue where you left off"
}
```

3. 재시도 사실 보고

```markdown
[ACP 재개]
- 세션: <session_id>
- 사유: <실패/중단 사유>
```

### 6. 주의

- `resumeSessionId`는 Codex, Claude Code만 지원
- 다른 에이전트면 새 세션으로 재시도
- 다른 에이전트가 시작한 ACP 세션은 무시

### 7. 실행 규칙

**모든 구현 작업은 ACP Claude를 사용한다.**

```json
{
  "runtime": "acp",
  "agentId": "claude",
  "task": "작업 내용"
}
```

Claude 사용 이유:
- 컨텍스트 유지
- resumeSessionId로 재개 가능
- 완료 추적 가능
- 코드 품질 우수

### 7. 보고 방식

- 문제 없고 진행 중인 것도 없으면: `HEARTBEAT_OK`
- 완료/재시도 있으면: 요약 메시지
