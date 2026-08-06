#!/usr/bin/env bash
set -euo pipefail

mode="link"
skip_plugin_sync=0
dry_run=0

usage() {
  cat <<'EOF'
사용법: bash ./scripts/install.sh [--mode link|copy] [--skip-plugin-sync] [--dry-run]

  --mode link          저장소를 Neovim 설정 경로에 심볼릭 링크로 연결(기본값)
  --mode copy          .git을 제외한 설정 파일을 복사
  --skip-plugin-sync   플러그인 동기화를 건너뜀
  --dry-run            변경 예정 경로만 출력
EOF
}

while (($# > 0)); do
  case "$1" in
    --mode)
      [[ $# -ge 2 ]] || { echo "--mode 값이 필요합니다." >&2; exit 2; }
      mode="$2"
      shift 2
      ;;
    --skip-plugin-sync)
      skip_plugin_sync=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "알 수 없는 옵션: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "$mode" != "link" && "$mode" != "copy" ]]; then
  echo "--mode는 link 또는 copy여야 합니다." >&2
  exit 2
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "$script_dir/.." && pwd -P)"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
if [[ "$config_home" != /* ]]; then
  config_home="$PWD/$config_home"
fi
destination="$config_home/nvim"

if [[ ! -f "$repo_root/init.lua" ]]; then
  echo "저장소 루트에서 init.lua를 찾지 못했습니다: $repo_root" >&2
  exit 1
fi

if [[ "$repo_root" != "$destination" ]]; then
  case "$destination/" in
    "$repo_root/"*)
      echo "설치 경로가 저장소의 하위 디렉터리일 수 없습니다." >&2
      exit 1
      ;;
  esac
  case "$repo_root/" in
    "$destination/"*)
      echo "저장소가 설치 경로의 하위 디렉터리일 수 없습니다." >&2
      exit 1
      ;;
  esac
fi

if ((dry_run)); then
  echo "방식: $mode"
  echo "원본: $repo_root"
  echo "설치 경로: $destination"
  if [[ -e "$destination" || -L "$destination" ]]; then
    echo "기존 설정은 ${destination}.backup-<시각> 형태로 백업됩니다."
  fi
  exit 0
fi

backup_path=""
changed=0
already_linked=0

if [[ -L "$destination" ]]; then
  resolved_destination="$(cd -- "$destination" && pwd -P)"
  if [[ "$resolved_destination" == "$repo_root" ]]; then
    already_linked=1
  fi
fi

rollback() {
  status=$?
  if ((status != 0 && changed)); then
    if [[ -L "$destination" ]]; then
      rm -f -- "$destination"
    elif [[ -e "$destination" ]]; then
      rm -rf -- "$destination"
    fi
    if [[ -n "$backup_path" && -e "$backup_path" ]]; then
      mv -- "$backup_path" "$destination"
      echo "설치에 실패하여 기존 설정을 복구했습니다." >&2
    fi
  fi
  exit "$status"
}
trap rollback EXIT

installed=0
if [[ "$repo_root" == "$destination" || "$already_linked" == 1 ]]; then
  echo "저장소가 이미 Neovim 설정 경로에 있습니다: $destination"
  installed=1
else
  if [[ -e "$destination" || -L "$destination" ]]; then
    timestamp="$(date +%Y%m%d-%H%M%S)"
    backup_path="${destination}.backup-${timestamp}"
    suffix=1
    while [[ -e "$backup_path" || -L "$backup_path" ]]; do
      backup_path="${destination}.backup-${timestamp}-${suffix}"
      ((suffix += 1))
    done
    mkdir -p -- "$(dirname -- "$destination")"
    mv -- "$destination" "$backup_path"
    changed=1
    echo "기존 설정 백업: $backup_path"
  else
    mkdir -p -- "$(dirname -- "$destination")"
    changed=1
  fi

  if [[ "$mode" == "link" ]]; then
    ln -s -- "$repo_root" "$destination"
  else
    mkdir -- "$destination"
    shopt -s dotglob nullglob
    for item in "$repo_root"/*; do
      [[ "$(basename -- "$item")" == ".git" ]] && continue
      cp -a -- "$item" "$destination/"
    done
    shopt -u dotglob nullglob
  fi
  installed=1
  echo "Neovim 설정 설치 완료: $destination"
fi

if ((installed && !skip_plugin_sync)); then
  if command -v nvim >/dev/null 2>&1; then
    echo "플러그인을 동기화합니다..."
    nvim --headless "+Lazy! sync" "+qa"
    echo "적용이 끝났습니다. nvim을 실행한 뒤 :checkhealth로 상태를 확인하세요."
  else
    echo "경고: nvim 명령을 찾지 못해 플러그인 설치를 건너뜁니다." >&2
  fi
fi

trap - EXIT
