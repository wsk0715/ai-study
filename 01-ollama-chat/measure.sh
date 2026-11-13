# 실습 01 측정: 모델마다 예열 1회 뒤 한국어 질문 3개로 생성 속도와 적재 위치를 기록한다.
# 마지막에 "생성 속도는 메모리 대역폭이 정한다"를 검사한다.
#
# 사용법: bash measure.sh
#   VRAM_BW_GBPS: GPU의 VRAM 대역폭(GB/s). 기본값 256은 RTX 4070 Laptop GPU의 공개 사양이다. 다른 GPU면 바꿔서 실행한다.

# Windows 기본 설치 경로. PATH에 ollama가 있으면 그것을 쓴다.
O="$(command -v ollama || echo "$LOCALAPPDATA/Programs/Ollama/ollama.exe")"
VRAM_BW_GBPS="${VRAM_BW_GBPS:-256}"
QUESTIONS=("양자화를 두 문장으로 설명해 줘." "파이썬 리스트와 튜플의 차이를 세 줄로 알려 줘." "서울에서 부산까지 KTX로 가는 장점을 두 가지 말해 줘.")

# 전원: 1이면 배터리, 2이면 전원 연결. 노트북 GPU는 배터리에서 크게 느려지므로 2에서 잰다.
echo "== 전원"
powershell -NoProfile -Command "(Get-CimInstance Win32_Battery).BatteryStatus"

fail=0
for M in qwen3:8b-q4_K_M qwen3:8b-q8_0; do
  echo "######## $M"
  # 예열: 모델을 VRAM에 올리는 시간(load)을 측정에서 빼기 위해 한 번 먼저 돌린다.
  "$O" run "$M" --verbose --think=false "안녕" 2>&1 | grep -aE "load duration"

  rates=()
  for q in "${QUESTIONS[@]}"; do
    echo "== Q: $q"
    # --verbose 통계 중 생성 속도(eval rate)와 생성 토큰 수만 남긴다. grep -a: 제어 문자가 섞여도 텍스트로 읽는다.
    stats="$("$O" run "$M" --verbose --think=false "$q" 2>&1 | grep -aE "^eval (count|rate)")"
    echo "$stats"
    rates+=("$(echo "$stats" | awk '/^eval rate/ {print $3}')")
  done

  echo "== ollama ps"
  ps_line="$("$O" ps | grep -a "$M")"
  echo "$ps_line"
  echo "== VRAM"
  nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader

  # 검사: 모델이 전부 GPU에 올라갔다면, 토큰마다 가중치 전체를 VRAM에서 한 번 읽으므로
  # 생성 속도의 상한은 "대역폭 ÷ 모델 파일 크기"다. 실측이 이 상한을 넘지 않고 80% 이상이면
  # 생성 속도가 연산이 아니라 메모리 읽기에 묶여 있다고 본다.
  if echo "$ps_line" | grep -q "100% GPU"; then
    size_gb="$("$O" list | grep -a "^$M " | awk '{print $3}')"
    printf '%s\n' "${rates[@]}" | awk -v bw="$VRAM_BW_GBPS" -v size="$size_gb" '
      { sum += $1; n++ }
      END {
        avg = sum / n; bound = bw / size; ratio = avg / bound
        printf "== 검사: 평균 %.1f tokens/s, 상한 %.0f / %.1f = %.1f tokens/s, 비율 %.0f%%\n", avg, bw, size, bound, ratio * 100
        if (ratio > 1.0 || ratio < 0.8) { print "== 검사 실패: 상한의 80~100% 범위를 벗어났다"; exit 1 }
        print "== 검사 통과: 생성 속도가 메모리 대역폭 상한에 묶여 있다"
      }' || fail=1
  else
    echo "== 검사 생략: 일부가 CPU에 올라가 VRAM 대역폭 상한을 적용할 수 없다"
  fi

  # 다음 모델 측정에 영향을 주지 않게 내린다.
  "$O" stop "$M"
done
exit $fail
