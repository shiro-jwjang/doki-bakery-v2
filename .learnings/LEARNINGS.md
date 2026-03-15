# LEARNINGS.md

학습 내용, 교정, 베스트 프랙티스를 기록합니다.

---

## 교정 (Corrections)

## [LRN-20260315-001] Linear 이슈 상태 관리 워크플로우

**Logged**: 2026-03-15T15:03:00+09:00
**Priority**: high
**Status**: promoted
**Area**: config

### Summary
PR merge 전에 Linear 이슈를 Done으로 변경하면 안 됨

### Details
SNA-183 작업 중 PR 생성 후 바로 Done으로 변경함. 사용자 지적: "누가 이거 던으로 보냈지..183은 인 리뷰 가야지"

올바른 워크플로우:
```
Todo → In Progress → PR 생성 → In Review → PR merge → Done
```

### Suggested Action
1. PR 생성 후 반드시 In Review 상태로 변경
2. PR merge 확인 후에만 Done으로 변경
3. "이슈 처리는?" 질문에 성급하게 Done 처리 금지

### Metadata
- Source: user_feedback
- Related Files: TOOLS.md
- Tags: linear, workflow, git
- Pattern-Key: workflow.linear_state
- Recurrence-Count: 1
- First-Seen: 2026-03-15
- Last-Seen: 2026-03-15

### Resolution
- **Resolved**: 2026-03-15T15:04:00+09:00
- **Commit**: 9083b00
- **Promoted**: TOOLS.md (Linear 이슈 상태 관리 섹션)
- **Notes**: 상태를 In Review로 수정, TOOLS.md에 워크플로우 문서화

---

## 지식 갭 (Knowledge Gaps)

(기록 예정)

---

## 베스트 프랙티스 (Best Practices)

(기록 예정)
