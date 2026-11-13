# 01. Ollama 로컬 챗, VRAM·속도 관찰

## 목표

- 로컬 GPU에서 7B~8B 모델을 돌려 본다.
- 양자화 수준(Q4, Q8)에 따라 VRAM과 tokens/s가 어떻게 달라지는지 측정한다.
- VRAM을 넘었을 때 CPU로 밀리며 느려지는 현상을 확인한다.

## 절차

1. Ollama 설치: `winget install Ollama.Ollama` 후 터미널을 새로 연다.
2. 다른 터미널에서 VRAM 관찰: `nvidia-smi -l 1`
3. Q4 모델 실행: `ollama run qwen3:8b-q4_K_M --verbose --think=false`
   - 한국어로 같은 질문 3개를 던지고, `--verbose`가 출력하는 `eval rate`(tokens/s)를 적는다.
4. Q8 모델 실행: `ollama run qwen3:8b-q8_0 --verbose --think=false`
   - 같은 질문으로 반복한다.
5. 각 모델이 GPU와 CPU에 얼마나 올라갔는지 확인: `ollama ps`

- 모델: Qwen3 8B (2025-04, Apache 2.0, 한국어 포함 다국어 지원).
- 파일 크기는 Q4 5.2GB, Q8 8.9GB다. Q4는 VRAM 8GB에 들어가고 Q8은 넘치므로 일부가 CPU로 밀리는 것을 비교할 수 있다.
- Qwen3는 기본으로 생각(thinking) 출력을 먼저 낸다. 생각 토큰이 섞이면 두 모델의 속도 비교가 어긋나므로 끄고 측정한다. `--think=false`가 동작하지 않으면 질문 끝에 `/no_think`를 붙인다.
- 태그 목록: https://ollama.com/library/qwen3/tags

## 결과

전원 연결 상태, 질문 3개의 eval rate. 모델마다 예열 1회 뒤 측정했다. GPU 메모리는 8,188MiB다.

| 모델 | 파일 크기 | 적재 크기 (`ollama ps`) | VRAM 사용 | PROCESSOR | eval rate (tokens/s) |
|---|---|---|---|---|---|
| qwen3:8b-q4_K_M | 5.2GB | 5.6GB | 5,497MiB | 100% GPU | 46.60, 45.94, 45.76 |
| qwen3:8b-q8_0 | 8.9GB | 9.6GB | 6,125MiB | 35%/65% CPU/GPU | 12.52, 13.65, 13.61 |

배터리 상태에서 같은 측정을 했을 때 Q4는 12.85, 16.01 tokens/s였다. 노트북 GPU는 배터리에서 전력이 제한되므로 속도 측정은 전원을 연결하고 한다.

## 배운 점

-
