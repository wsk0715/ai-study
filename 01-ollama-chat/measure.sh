# 실습 01 측정: 모델마다 예열 1회 뒤 한국어 질문 3개로 생성 속도와 적재 위치를 기록한다.
# Windows 기본 설치 경로. PATH에 ollama가 있으면 그것을 쓴다.
O="$(command -v ollama || echo "$LOCALAPPDATA/Programs/Ollama/ollama.exe")"
# 전원: 1이면 배터리, 2이면 전원 연결. 노트북 GPU는 배터리에서 크게 느려지므로 2에서 잰다.
echo "== 전원"
powershell -NoProfile -Command "(Get-CimInstance Win32_Battery).BatteryStatus"
for M in qwen3:8b-q4_K_M qwen3:8b-q8_0; do
  echo "######## $M"
  # 예열: 모델을 VRAM에 올리는 시간(load)을 측정에서 빼기 위해 한 번 먼저 돌린다.
  "$O" run "$M" --verbose --think=false "안녕" 2>&1 | grep -aE "load duration"
  for q in "양자화를 두 문장으로 설명해 줘." "파이썬 리스트와 튜플의 차이를 세 줄로 알려 줘." "서울에서 부산까지 KTX로 가는 장점을 두 가지 말해 줘."; do
    echo "== Q: $q"
    # --verbose 통계 중 생성 속도(eval rate)와 생성 토큰 수만 남긴다. grep -a: 제어 문자가 섞여도 텍스트로 읽는다.
    "$O" run "$M" --verbose --think=false "$q" 2>&1 | grep -aE "^eval (count|rate)"
  done
  echo "== ollama ps"
  "$O" ps
  echo "== VRAM"
  nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader
  # 다음 모델 측정에 영향을 주지 않게 내린다.
  "$O" stop "$M"
done
