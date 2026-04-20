# M1 Technical Spec — 코어 로직 상세 정의

> 본 문서는 GDD/PRD의 M1 범위(F01, F03, F04, F05, F10)에서 기획서에 누락된 상세 스펙을 정의한다.
> 기존 구현을 기준으로 작성했으며, 쿄의 밸런스 확정 전까지 임시 수치를 사용한다.
> 최종 갱신: 2026-04-09 | 작성: 시로 (PM)

---

## 1. F01 방치형 생산 시스템 — 상세 스펙

### 1.1 생산 슬롯 동작

| 항목 | 스펙 |
|------|------|
| 슬롯 수 | ShopData.shop_level에 따라 결정. 1단계(shop_level_1): max_production_slots=3 (현재 .tres 기준) |
| 생산 사이클 | 레시피 배정 → production_time동안 진행 → 완료 → 수거 대기 |
| 자동반복 | auto_repeat 설정 시 수거 즉시 동일 레시피로 재시작. 기본값: ON |
| 진열대 최대 수량 | 슬롯당 1개. 완료된 빵은 수거(unlocked_recipes에 추가) 후 진열대(DisplaySlot)로 이동 |

### 1.2 생산 중 레시피 교체

- 교체 시 현재 생산 즉시 취소 (진행률 초기화, 골드/재료 환불 없음)
- M1에서는 생산 비용이 0이므로 페널티 없음
- 이미 완료된 슬롯은 수거 후에만 교체 가능

### 1.3 오프라인 시간 처리

```
offline_elapsed = now - last_save_timestamp
completed_batches = floor(offline_elapsed / recipe.production_time)
→ completed_batches 만큼 골드/경험치 일괄 지급
→ remain_time = offline_elapsed % recipe.production_time 로 슬롯 진행률 복원
```

- 오프라인 보상 캡: 24시간분까지만 계산 (초과분 무시)
- 생산 슬롯이 비어있으면 오프라인 보상 없음

### 1.4 판매 트리거 (M1)

M1에서 CustomerSpawner는 씬 트리 의존적 Timer 기반이므로, 코어 로직 테스트에서는 다음 방식으로 판매를 처리:

- **자동 판매 (AutoSell)**: 빵이 DisplaySlot에 올라가면 일정 시간 후 자동 판매
- SalesManager가 인벤토리 관리, CustomerPurchase가 구매 판정
- EconomyManager.sell_bread()로 골드/XP 획득
- purchase_probability: 0.8 (기본값, ShopData에서 설정 가능)

---

## 2. F03 재화 시스템 — 상세 스펙

### 2.1 재화 정의

| 재화 | 타입 | 획득 경로 | 소모 경로 |
|------|------|-----------|-----------|
| 골드 (Gold) | int | 빵 판매, 레벨업 보상 | 레시피 해금(MVP 제외), 매장 업그레이드 |
| 경험치 (EXP) | int | 빵 판매, 생산 완료, 이모티콘 보상 | 레벨업 시 소모 (차감 방식) |
| 전설의 황금빵 (Cash) | int | 레벨업 보상 (무료) | MVP에서 소모처 없음 |

### 2.2 보유 한도

| 재화 | 최대값 | 초과 시 |
|------|--------|---------|
| 골드 | 99,999,999 | 획득 불가 (캡) |
| 경험치 | 무제한 (레벨업 시 차감) | — |
| 전설의 황금빵 | 9,999 | 획득 불가 (캡) |

### 2.3 레벨업 보상 (임시 수치)

> ⚠️ 쿄 확정 필요. 아래는 임시값.

| 레벨 | 골드 보상 | 전설의 황금빵 |
|------|-----------|--------------|
| 2 | 100 | 1 |
| 3 | 200 | 1 |
| 4 | 300 | 1 |
| 5 | 500 | 2 |
| 6 | 700 | 2 |
| 7 | 1,000 | 2 |
| 8 | 1,500 | 3 |
| 9 | 2,000 | 3 |
| 10 | 5,000 | 5 |

---

## 3. F04 레벨링 시스템 — 상세 스펙

### 3.1 레벨업 메커니즘

```
경험치 누적 → 현재 레벨의 required_xp 충족 → 레벨업
- 경험치는 차감 방식 (remaining_xp = current_xp - required_xp)
- 다중 레벨업 지원 (while 루프)
```

### 3.2 만렙(Lv.10) 처리

- Lv.10 도달 후 추가 경험치 획득은 무시 (버림)
- MAX_LEVEL 상수 = 10
- 이미 MAX_LEVEL이면 add_experience()에서 경험치 추가하지 않음

### 3.3 레벨 테이블 (임시 수치)

> ⚠️ 쿄 확정 필요. LevelData .tres 기준.

| 레벨 | 필요 경험치 | 해금 레시피 | 골드 보상 |
|------|------------|-------------|-----------|
| 1 | 0 | bread_001 | 0 |
| 2 | 50 | bread_002 | 100 |
| 3 | 120 | bread_003 | 200 |
| 4 | 200 | — | 300 |
| 5 | 350 | bread_croissant | 500 |
| 6 | 550 | bread_004 | 700 |
| 7 | 800 | bread_005 | 1,000 |
| 8 | 1,200 | — | 1,500 |
| 9 | 1,800 | bread_006 | 2,000 |
| 10 | 3,000 | — | 5,000 |

### 3.4 해금 시나리오

- 레벨업 시 LevelData.unlock_recipes에 등록된 레시피가 unlocked_recipes에 추가
- 이미 해금된 레시피는 중복 추가하지 않음
- 해금 즉시 생산 슬롯에 배정 가능

---

## 4. F05 레시피 시스템 — 상세 스펙

### 4.1 레시피 데이터 구조

```
RecipeData (Resource):
  - id: String (예: "bread_001")
  - display_name: String
  - production_time: float (초)
  - base_price: int (판매가)
  - xp_reward: int (판매 시 획득 XP)
  - unlock_level: int
  - icon: Texture2D
  - tier: int (1=일반, 2=고급, 3=희귀) ← 추가 필요
```

### 4.2 레시피 임시 데이터

> ⚠️ 쿄 확정 필요. bread_001은 .tres 파일 누락 상태.

| ID | 이름 | 생산시간(초) | 판매가 | XP | 해금Lv | 등급 |
|----|------|-------------|--------|-----|--------|------|
| bread_001 | 기본 식빵 | 10 | 10 | 5 | 1 | 일반 |
| bread_002 | 버터롤 | 15 | 20 | 8 | 2 | 일반 |
| bread_003 | 초코빵 | 20 | 35 | 12 | 3 | 일반 |
| bread_004 | 크루아상 | 30 | 60 | 20 | 5 | 고급 |
| bread_005 | 메론빵 | 25 | 45 | 15 | 6 | 일반 |
| bread_006 | 단팥빵 | 35 | 80 | 25 | 7 | 고급 |
| bread_007 | 마카롱 | 45 | 120 | 40 | 8 | 고급 |
| bread_008 | 베이글 | 20 | 40 | 14 | 4 | 일반 |
| bread_009 | 바게트 | 50 | 150 | 50 | 9 | 희귀 |
| bread_010 | 웨딩케이크 | 120 | 500 | 150 | 10 | 희귀 |

### 4.3 등급 효과

| 등급 | 생산시간 배율 | 판매가 배율 | 비고 |
|------|-------------|-----------|------|
| 일반(1) | ×1.0 | ×1.0 | 기본 |
| 고급(2) | ×1.5 | ×2.0 | 가성비 좋음 |
| 희귀(3) | ×2.0 | ×3.0 | 장기 투자 |

### 4.4 해금 방식

- M1/MVP: 가챠 없이 레벨 도달 시 고정 해금
- 해금되지 않은 레시피는 생산 불가 (BakeryManager에서 검증)
- 해금 목록은 GameManager.unlocked_recipes: Array로 관리

---

## 5. F10 세이브 & 시스템 — 상세 스펙

### 5.1 세이브 데이터 스키마 (v1)

```json
{
  "version": 1,
  "timestamp": "2026-04-09T12:00:00Z",
  "game": {
    "gold": 0,
    "legendary_bread": 0,
    "level": 1,
    "experience": 0,
    "play_time": 0.0,
    "game_state": "menu",
    "avatar_data_id": "",
    "unlocked_recipes": ["bread_001"],
    "shop_stage": 1
  },
  "bakery": {
    "production_slots": [
      {
        "slot_index": 0,
        "recipe_id": "bread_001",
        "start_time": "2026-04-09T11:55:00Z",
        "is_active": true,
        "auto_repeat": true
      }
    ]
  }
}
```

### 5.2 자동 저장 트리거

| 이벤트 | 저장 |
|--------|------|
| _process (60초마다) | ✅ |
| 레벨업 | ✅ |
| 레시피 해금 | ✅ |
| 빵 판매 | ❌ (너무 빈번) |
| 수동 저장 요청 | ✅ |

### 5.3 로드 흐름

```
1. 세이브 파일 존재 확인 (user://save.json)
2. 파일 읽기 → JSON 파싱
3. version 체크 → 마이그레이션 (필요시)
4. GameManager.set_state(game_data)
5. BakeryManager.restore_slots(bakery.production_slots)
6. 오프라인 시간 보상 계산 및 지급
```

### 5.4 세이브 버전 마이그레이션

| 버전 | 변경 내용 | 마이그레이션 |
|------|-----------|-------------|
| 1 | 초기 포맷 | — |
| 2 (예정) | inventory 필드 추가 | 기본값으로 채움 |

- 더 높은 버전의 세이브는 로드 실패 → 새 게임 시작
- 더 낮은 버전은 순차적으로 마이그레이션

### 5.5 손상된 세이브 처리

- JSON 파싱 실패 → 백업 파일(save.json.bak) 시도
- 백업도 실패 → 새 게임 시작 + 유저에게 알림
- 백업은 매 저장 시 이전 파일을 .bak으로 복사

---

## 6. ShopData 스펙 보완

### 6.1 매장 단계별 설정

| 항목 | 1단계 (초기) | 2단계 (확장) |
|------|-------------|-------------|
| shop_level | 1 | 2 |
| max_production_slots | 3 | 4 |
| upgrade_cost | 0 | 5,000 |
| spawn_interval (초) | 15 | 10 |
| unlock_condition | level 1 | level 10 |
| max_customers | 3 | 5 |

---

## 7. 알려진 구현 갭 (TODO)

아래 항목은 기획서에 정의되어 있으나 현재 코드에 미구현/불일치인 것들:

| ID | 항목 | 상태 | 비고 |
|----|------|------|------|
| GAP-1 | bread_001.tres 누락 | 🔴 | level_01이 참조하나 파일 없음 |
| GAP-2 | SaveData vs SaveManager 구조 불일치 | 🔴 | unlocked_recipes/shop_stage/production_slots 누락 |
| GAP-3 | BakeryManager.restore_slots() 미연결 | 🔴 | 메서드는 있으나 로드 시 호출 안 됨 |
| GAP-4 | ShopData 연동 없음 | 🟡 | _max_slots 하드코딩, CustomerSpawner 설정 미호출 |
| GAP-5 | GameManager.bread_inventory 미사용 | 🟡 | 선언만 있고 SalesManager가 인벤토리 관리 |
| GAP-6 | RecipeData.tier 필드 없음 | 🟡 | 등급 구분 코드에 반영 안 됨 |

---

## 8. 쿄 확정 요청 항목

다음 항목은 쿄의 기획 확정이 필요함:

1. 레시피 목록 및 밸런스 수치 (이름, 생산시간, 판매가, XP, 등급)
2. 레벨 테이블 확정 (필요 경험치, 해금 레시피, 보상)
3. 레벨업 당 전설의 황금빵 지급량
4. 손님 스폰 주기 및 구매 확률
5. 매장 업그레이드 비용
6. 오프라인 보상 캡 (24시간이 적절한지)
7. 등급별 배율 수치
