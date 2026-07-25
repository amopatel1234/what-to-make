#!/usr/bin/env bash
# Computational architecture sensor for agent harnessing.
# Fails when deleted layers or forbidden SwiftUI/Combine state wrappers reappear.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCES="${ROOT}/Sources"
failed=0

emit_failure() {
  local title="$1"
  local detail="$2"
  local remediation="$3"
  echo "::error::${title}"
  echo "error: ${title}" >&2
  echo "${detail}" >&2
  echo >&2
  echo "${remediation}" >&2
  echo >&2
  failed=1
}

if [[ ! -d "${SOURCES}" ]]; then
  echo "error: Sources/ not found at ${SOURCES}" >&2
  exit 1
fi

# --- Folder boundaries (deleted after SwiftUI-native refactor) ---

for layer in UseCases Repositories ViewModels; do
  path="${SOURCES}/${layer}"
  if [[ -e "${path}" ]]; then
    emit_failure \
      "Forbidden layer present: Sources/${layer}" \
      "Found path: ${path}" \
      "Remediation: Remove Sources/${layer}. Prefer Helpers/ for pure logic, or a thin @Observable coordinator under Views/ for transient UI state only. See docs/project-context.md → Architecture / Critical Don't-Miss Rules."
  fi
done

# --- Forbidden property wrappers (ObservableObject / Combine-style state) ---

# Match the wrapper token as used in Swift source (avoids bare words in comments when possible).
wrapper_pattern='@(Published|StateObject|ObservedObject)([^A-Za-z0-9_]|$)'

while IFS= read -r -d '' file; do
  if grep -nE "${wrapper_pattern}" "${file}" >/dev/null 2>&1; then
    matches="$(grep -nE "${wrapper_pattern}" "${file}" | sed 's/^/  /')"
    rel="${file#"${ROOT}/"}"
    emit_failure \
      "Forbidden property wrapper in ${rel}" \
      "Matches:${matches}" \
      "Remediation: Do not use @Published, @StateObject, or @ObservedObject. Prefer @Observable + @Bindable for coordinators, and @State / @Query / @AppStorage / @Environment in views. See docs/project-context.md → Framework-Specific Rules / State management."
  fi
done < <(find "${SOURCES}" -type f -name '*.swift' -print0 | sort -z)

if [[ "${failed}" -ne 0 ]]; then
  echo "Architecture check failed." >&2
  exit 1
fi

echo "Architecture check passed."
