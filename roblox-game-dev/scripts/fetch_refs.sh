#!/usr/bin/env bash
# fetch_refs.sh — забрать ОДНУ папку из внешней визуальной библиотеки izzyfrm/roblox-ai
# без скачивания всех ~1.3 ГБ (shallow + blobless + sparse checkout).
# Картинки в скилл не кладём: тянем на время работы, в проект/скилл не коммитим.
# Правила и индекс папок: references/builder/visual-reference-library.md
set -euo pipefail

REPO_URL="${REFS_REPO_URL:-https://github.com/izzyfrm/roblox-ai.git}"

usage() {
  cat >&2 <<'EOF'
Использование: fetch_refs.sh <папка[/подпапка]> [куда]

  <папка[/подпапка]>  путь внутри репозитория, например:
                        ui-styles/13-pet-collector-grid
                        game-refs/horror
                        style-refs/candy
                        roblox-docs/ui
  [куда]              каталог назначения (по умолчанию ./refs/<имя>, где <имя> — путь с '/' -> '_')

Делает: git clone --depth 1 --filter=blob:none --sparse + sparse-checkout set <путь>.
Скачиваются только файлы нужной папки (+ README.md и файлы корня репозитория).
Повторный вызов в тот же каталог добавляет ещё одну папку (sparse-checkout add).

Переменные: REFS_REPO_URL — другой источник (форк/зеркало).
Лицензия: game-refs/thumbnails/logos/ui-styles — только вдохновение, не перезаливать и не обводить.
EOF
}

if [[ $# -lt 1 || $# -gt 2 || "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && exit 0
  exit 2
fi

path="${1%/}"
path="${path#./}"

# защита от абсолютных путей и выхода из репозитория
if [[ -z "$path" || "$path" == /* || "$path" == *..* ]]; then
  echo "Ошибка: недопустимый путь '$1' (нужен относительный путь внутри репозитория)." >&2
  exit 2
fi

name="${path//\//_}"
dest="${2:-./refs/$name}"

command -v git >/dev/null 2>&1 || { echo "Ошибка: git не найден." >&2; exit 1; }

if [[ -d "$dest/.git" ]]; then
  echo "Каталог $dest уже клон: добавляю '$path' в sparse-checkout."
  git -C "$dest" sparse-checkout add -- "$path"
else
  if [[ -e "$dest" && -n "$(ls -A "$dest" 2>/dev/null || true)" ]]; then
    echo "Ошибка: $dest существует и не пуст." >&2
    exit 1
  fi
  mkdir -p "$(dirname "$dest")"
  git clone --quiet --depth 1 --filter=blob:none --sparse "$REPO_URL" "$dest"
  git -C "$dest" sparse-checkout set -- "$path"
fi

if [[ ! -d "$dest/$path" ]]; then
  echo "Предупреждение: '$path' не найден в репозитории (папку могли переименовать)." >&2
  echo "Доступные верхние папки:" >&2
  git -C "$dest" ls-tree --name-only -d HEAD >&2 || true
  exit 1
fi

count="$(find "$dest/$path" -type f ! -iname 'README.md' | wc -l | tr -d ' ')"
echo "Готово: $dest/$path ($count файлов, без README)"
echo "Напоминание: референсы третьих лиц — вдохновение. Не перезаливать в Roblox, не обводить, не класть в репозиторий игры."
