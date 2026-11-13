# 01. Ollama 로컬 챗, VRAM·속도 관찰

## 목표

- 로컬 GPU에서 7B~8B 모델을 돌려 본다.
- 양자화 수준(Q4, Q8)에 따라 VRAM과 tokens/s가 어떻게 달라지는지 측정한다.
- VRAM을 넘었을 때 CPU로 밀리며 느려지는 현상을 확인한다.

## 절차

1. Ollama 설치: `winget install Ollama.Ollama` 후 터미널을 새로 연다.
2. 다른 터미널에서 VRAM 관찰: `nvidia-smi -l 1`
3. Q4 모델 실행: `ollama run qwen2.5-coder:7b --verbose`
   - 한국어로 같은 질문 3개를 던지고, `--verbose`가 출력하는 `eval rate`(tokens/s)를 적는다.
4. Q8 모델 실행: `ollama run qwen2.5-coder:7b-instruct-q8_0 --verbose`
   - 같은 질문으로 반복한다.
5. 각 모델이 GPU와 CPU에 얼마나 올라갔는지 확인: `ollama ps`

- 태그 이름은 https://ollama.com/library/qwen2.5-coder/tags 에서 확인한다.

## 결과

| 모델 | VRAM 사용 | `ollama ps` PROCESSOR | eval rate (tokens/s) |
|---|---|---|---|
| qwen2.5-coder:7b (Q4) | | | |
| qwen2.5-coder:7b-instruct-q8_0 | | | |

## 배운 점

-
