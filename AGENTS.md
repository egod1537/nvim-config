# Codex 작업 지침

## 저장소 목적

이 저장소는 LazyVim 기반 Neovim 설정이다. 사용자가 이 저장소를 클론한 뒤 Codex에게 설정 적용을 요청하면, 현재 설정을 잃지 않도록 백업하고 이 저장소를 실제 Neovim 설정 경로에 연결해야 한다.

## 사용자가 설치 또는 적용을 요청할 때

1. 운영체제를 확인한다. Windows의 기본 설치 대상은 `$env:LOCALAPPDATA\nvim`이고, Linux/macOS는 `${XDG_CONFIG_HOME:-$HOME/.config}/nvim`이다.
2. `nvim`, `git`, `clangd`, `g++` 명령의 존재와 버전을 확인한다. 없는 선택 도구는 임의로 설치하지 말고 사용자에게 알려 준다.
3. 먼저 운영체제에 맞는 dry-run 명령으로 변경 예정 경로를 보여 준다.

   ```powershell
   & .\scripts\install.ps1 -Mode Junction -WhatIf
   ```

   ```bash
   bash ./scripts/install.sh --mode link --dry-run
   ```

4. 대상 경로가 올바르면 운영체제에 맞는 명령을 실행한다.

   ```powershell
   & .\scripts\install.ps1 -Mode Junction
   ```

   ```bash
   bash ./scripts/install.sh --mode link
   ```

   Junction 또는 심볼릭 링크 방식은 클론한 저장소를 설정 원본으로 유지하므로 기본 권장 방식이다. 사용자가 링크를 원하지 않거나 파일 시스템이 링크를 지원하지 않을 때만 Windows에서는 `-Mode Copy`, Linux/macOS에서는 `--mode copy`를 사용한다.

5. 설치 스크립트가 출력한 백업 경로를 사용자에게 전달한다.
6. 설치 후 `nvim --headless "+checkhealth" "+qa"`처럼 출력이 보장되지 않는 검증에 의존하지 않는다. Lua 파일 문법 검사, 설치 경로 확인, `nvim --headless "+Lazy! sync" "+qa"`의 종료 코드를 확인하고, 사용자가 대화형 Neovim에서 `:checkhealth`를 실행하도록 안내한다.

## 안전 규칙

- 기존 Neovim 설정을 삭제하거나 덮어쓰지 않는다. 설치 스크립트의 타임스탬프 백업을 사용한다.
- `$env:LOCALAPPDATA\nvim-data`는 플러그인 캐시와 상태가 들어 있으므로 사용자의 명시적인 요청 없이 삭제하지 않는다.
- 사용자별 절대 경로를 추적 파일에 새로 하드코딩하지 않는다.
- `clangd`와 `g++`는 우선 `PATH`에서 찾는다. 필요하면 각각 `NVIM_CLANGD_PATH`, `NVIM_CXX` 환경 변수를 사용하도록 안내한다.
- 알고리즘 문제 풀이 루트의 기본값은 `~/proj/ps`이다. 다른 위치를 사용하면 `NVIM_PS_ROOT` 환경 변수를 안내한다.
- 저장소에 이미 존재하는 사용자 변경 사항은 보존하며, 설치와 무관한 파일은 수정하지 않는다.
