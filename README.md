# Neovim 설정

[LazyVim](https://github.com/LazyVim/LazyVim) 기반 Neovim 설정이다. 저장소를 클론한 뒤 Codex에게 적용을 요청하면 기존 설정을 백업하고, 플러그인 설치와 기본 검증까지 진행할 수 있도록 구성되어 있다.

## Codex로 적용하기

### 1. 저장소 클론

원하는 작업 디렉터리에서 다음 명령을 실행한다. 저장소를 반드시 `%LOCALAPPDATA%\nvim`에 직접 클론할 필요는 없다.

```powershell
git clone https://github.com/egod1537/nvim-config
Set-Location .\nvim-config
```

### 2. Codex에게 요청

이 저장소를 작업 디렉터리로 Codex를 연 뒤 다음과 같이 요청한다.

```text
AGENTS.md 지침에 따라 이 Neovim 설정을 내 환경에 적용하고 검증해 줘.
```

Codex는 다음 작업을 수행하도록 지침이 설정되어 있다.

- 현재 Neovim 설정과 필수 명령 확인
- 실제 변경 전 설치 경로 미리 보기
- 기존 Neovim 설정을 타임스탬프가 붙은 디렉터리로 백업
- Windows에서는 Junction, Linux/macOS에서는 심볼릭 링크로 저장소 연결
- LazyVim 플러그인 동기화 및 기본 검증
- 백업 위치와 추가로 필요한 도구 안내

Junction 또는 심볼릭 링크 방식에서는 이 저장소가 설정의 원본이 된다. 이후 저장소에서 `git pull`하면 별도의 복사 없이 최신 설정이 바로 적용된다.

## 직접 적용하기

### Windows

Codex 없이 설치하려면 PowerShell에서 저장소 루트로 이동한 뒤 설치 스크립트를 실행한다.

먼저 실제 변경 없이 작업 내용을 확인한다.

```powershell
& .\scripts\install.ps1 -Mode Junction -WhatIf
```

표시된 경로가 올바르면 설치한다.

```powershell
& .\scripts\install.ps1 -Mode Junction
```

Junction을 사용하고 싶지 않다면 설정 파일을 복사할 수 있다. 복사 방식은 저장소 변경 사항이 자동 반영되지 않으므로 업데이트할 때 다시 실행해야 한다.

```powershell
& .\scripts\install.ps1 -Mode Copy
```

플러그인 설치를 나중에 진행하려면 `-SkipPluginSync`를 추가한다. 이후 Neovim에서 `:Lazy sync`를 실행하면 된다.

### Linux/macOS

먼저 변경 내용을 확인한 뒤 적용한다.

```bash
bash ./scripts/install.sh --mode link --dry-run
bash ./scripts/install.sh --mode link
```

심볼릭 링크 대신 파일을 복사하려면 `--mode copy`, 플러그인 설치를 건너뛰려면 `--skip-plugin-sync`를 사용한다.

## 요구 사항

- Windows PowerShell 또는 Linux/macOS 셸
- Neovim: 현재 `v0.12.4`에서 사용 및 확인됨
- Git: `lazy.nvim`과 플러그인 다운로드에 필요
- Nerd Font 계열 글꼴: 아이콘 표시를 위해 권장
- C++ 기능 사용 시 `g++` 또는 호환 컴파일러
- 외부 LLVM 설치본을 사용하려면 `clangd`

`clang-format`과 `codelldb`는 Mason이 자동으로 설치한다. `clangd`가 `PATH`에 있으면 해당 설치본을 사용하고, 없으면 LazyVim과 Mason의 기본 설정을 사용한다.

## 사용자별 경로 설정

설정 파일에는 특정 사용자 이름이나 설치 경로를 하드코딩하지 않는다. 실행 파일은 기본적으로 `PATH`에서 찾으며, 필요한 경우 다음 사용자 환경 변수로 경로를 지정할 수 있다.

Windows PowerShell에서는 다음과 같이 사용자 환경 변수를 설정할 수 있다.

```powershell
[Environment]::SetEnvironmentVariable("NVIM_CLANGD_PATH", "C:\Program Files\LLVM\bin\clangd.exe", "User")
[Environment]::SetEnvironmentVariable("NVIM_CXX", "C:\msys64\ucrt64\bin\g++.exe", "User")
[Environment]::SetEnvironmentVariable("NVIM_PS_ROOT", "C:\Users\<사용자>\proj\ps", "User")
```

환경 변수를 설정한 뒤 새 터미널에서 Neovim을 실행한다.

Linux/macOS에서는 셸 설정 파일에 같은 이름의 환경 변수를 `export`한다.

- `NVIM_CLANGD_PATH`: 사용할 `clangd` 실행 파일
- `NVIM_CXX`: clangd의 query driver 및 CompetiTest 컴파일러
- `NVIM_PS_ROOT`: Competitive Companion 자동 수신을 활성화할 작업 디렉터리

`NVIM_PS_ROOT`를 지정하지 않으면 `~/proj/ps`를 사용한다.

## 주요 구성

- `lazy.nvim` 기반 플러그인 관리
- VS Code 색상 테마
- `clangd`, `clang-format`, `codelldb` 기반 C/C++ 개발 환경
- CompetiTest 테스트 실행 및 Competitive Companion 연동
- AtCoder 자동 완성 스니펫
- OSC 52 기반 클립보드 복사

Competitive Companion은 Neovim의 현재 작업 디렉터리가 `NVIM_PS_ROOT`와 같을 때 기본 포트 `27121`에서 자동으로 대기한다. 여러 Neovim 인스턴스를 열어도 하나의 인스턴스만 수신 서버를 실행한다.

## 설치 확인

설치 후 Neovim에서 다음 명령으로 상태를 확인한다.

```vim
:Lazy sync
:Mason
:checkhealth
```

## 기존 설정 복구

설치 스크립트는 기존 설정을 다음 형태의 경로로 이동하며 삭제하지 않는다.

Windows에서는 `%LOCALAPPDATA%\nvim.backup-yyyyMMdd-HHmmss`, Linux/macOS에서는 `~/.config/nvim.backup-yyyyMMdd-HHmmss` 형태로 백업한다. `XDG_CONFIG_HOME`을 지정했다면 해당 디렉터리를 기준으로 한다.

복구할 때는 새로 설치된 `nvim` 링크 또는 디렉터리의 이름을 변경하고, 원하는 백업 디렉터리의 이름을 다시 `nvim`으로 변경한다. Neovim의 데이터 디렉터리에는 플러그인 캐시와 상태가 있으므로 별도로 초기화하려는 경우가 아니면 삭제할 필요가 없다.
