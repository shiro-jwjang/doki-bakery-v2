# HEARTBEAT.md

## ACP 세션 자동 트래킹

하트비트마다 다음을 수행:
1. `sessions_list(kinds=["acp"])`로 활성 ACP 세션 확인
2. 진행 중인 세션이 있으면 상태 보고
3. 완료된 세션이 있으면 결과 확인 및 알림

### 확인 방법
```
sessions_list kinds=["acp"] limit=5
sessions_history sessionKey=<session_key> limit=10
```

### 보고 형식
- 진행 중: "🔄 {agent} 작업 중: {task}"
- 완료: "✅ {agent} 완료: {result}"
- 실패: "❌ {agent} 실패: {error}"

# Add tasks below when you want the agent to check something periodically.
