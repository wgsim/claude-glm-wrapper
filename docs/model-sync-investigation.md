# Claude-by-GLM 모델 동기화 이슈 조사

## 문제

claude-by-glm 세션과 공식 claude 세션 간에 간헐적으로 모델이 동기화되는 현상.
- GLM 세션에서 사용 중인 모델이 새로 시작된 공식 claude 세션에 반영됨
- 또는 공식 claude 세션의 모델이 열려있던 GLM 세션에 반영됨
- **항상 발생하지는 않고 간헐적**

## 조사 결과

### 1. settings.json 공유 확인

두 세션 모두 **동일한 `~/.claude/settings.json`을 읽고 있음** (lsof로 확인):

```
# GLM 세션 (CLAUDE_SETTINGS 설정했음에도)
claude  96691  10r  REG  ~/.claude/settings.json
claude  96691  12r  REG  ~/.claude/settings.json
... (10개 FD)

# 공식 세션
claude  57811  32r  REG  ~/.claude/settings.json
```

**결론**: `CLAUDE_SETTINGS` 환경변수는 `settings.json` 읽기를 대체하지 않고, **추가 레이어로만 동작**함. 글로벌 `settings.json`은 항상 읽힘.

### 2. KQUEUE (파일 감시) 활성

양쪽 세션 모두 KQUEUE를 열고 있어 `settings.json` 변경을 **실시간 감지**:

```
claude  96691  3u  KQUEUE  count=0, state=0x12
claude  57811  3u  KQUEUE  count=1, state=0x10
```

### 3. 현재 settings.json 상태

- `model` 키 **없음** (현재 시점)
- `effortLevel`, `enabledPlugins`, `statusLine` 등만 존재
- 하지만 과거에 `model` 키가 기록된 적이 있을 수 있음 (간헐적 쓰기 추정)

### 4. ~/.claude.json 공유

- `$HOME/.claude.json`은 모든 세션이 공유 (on-demand read/write)
- 프로젝트별 `lastModelUsage` 등 모델 관련 상태 저장
- `CLAUDE_CONFIG_DIR`로도 격리 불가 (HOME 기반 하드코딩)

### 5. CLAUDE_CONFIG_DIR 지원 확인

바이너리 분석 결과 **공식 지원**:

```js
function q9() {
    return process.env.CLAUDE_CONFIG_DIR ?? path.join(os.homedir(), ".claude")
}
```

- `~/.claude` 전체를 다른 경로로 대체 가능
- 단, plugins/skills/commands/CLAUDE.md 등도 분리됨
- 심볼릭 링크로 공유 리소스 연결 가능하나, **원인 미확정 상태에서 적용은 시기상조**

## 동기화 경로 (추정, 미확정)

```
세션 A에서 모델 변경
    ↓
settings.json에 model 키 기록 (간헐적)
    ↓
세션 B가 KQUEUE로 감지
    ↓
모델 동기화 발생
```

또는:

```
세션 A에서 모델 변경
    ↓
~/.claude.json에 상태 기록
    ↓
세션 B가 시작 시 또는 특정 이벤트에서 읽기
    ↓
모델 동기화 발생
```

**어느 경로인지는 아직 확정되지 않음.**

## 현재 대응: 모니터링 도구

### glm-watch-settings

`settings.json`과 `.claude.json` 모두 감시하는 스크립트 생성 완료:

```bash
# 백그라운드 실행
glm-watch-settings --bg

# 중지
glm-watch-settings --stop

# 로그 확인
glm-watch-settings --log

# 요약 리포트 (변경 횟수, MODEL 이벤트 등)
glm-watch-settings --report
```

- 위치: `bin/glm-watch-settings`
- 로그: `~/.claude/glm-sessions/settings-watch.log`
- 스냅샷: `~/.claude/glm-sessions/.snapshots/` (MODEL 변경 시 자동 저장)

## 다음 단계

1. **watcher 실행 상태 유지** → 모델 동기화 재현 대기
2. 재현 시 `glm-watch-settings --report` 실행 → 어떤 파일이 원인인지 확인
3. 원인 확정 후:
   - `settings.json`이 원인 → `CLAUDE_CONFIG_DIR` + 심볼릭 링크 적용
   - `.claude.json`이 원인 → 다른 우회 방법 필요
   - 둘 다 아닌 경우 → Claude Code 내부 IPC 가능성, 외부 제어 어려움
