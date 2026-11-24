#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Reutiliza ferramentas instaladas ou baixa versões locais, sem precisar de sudo.
tools_dir="$PWD/.tools"
bin_dir="$tools_dir/bin"
pandoc_version=3.5
tectonic_version=0.15.0

prepare_download() {
  if [[ "$(uname -s)" != Linux || "$(uname -m)" != x86_64 ]]; then
    echo 'O download automático requer Linux x86_64 (incluindo WSL).' >&2
    echo 'Em outro sistema, instale Pandoc e Tectonic no PATH.' >&2
    exit 1
  fi
  for dependency in curl tar; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
      echo "Falta $dependency. No Ubuntu: sudo apt install curl tar" >&2
      exit 1
    fi
  done
  mkdir -p "$bin_dir"
}

if command -v pandoc >/dev/null 2>&1; then
  pandoc_bin="$(command -v pandoc)"
else
  pandoc_bin="$bin_dir/pandoc"
  if [[ ! -x "$pandoc_bin" ]]; then
    prepare_download
    echo "Baixando Pandoc $pandoc_version para .tools/ (somente na primeira execução)..."
    archive="$(mktemp "$tools_dir/pandoc.XXXXXX")"
    curl --fail --location --retry 2 --silent --show-error \
      "https://github.com/jgm/pandoc/releases/download/$pandoc_version/pandoc-$pandoc_version-linux-amd64.tar.gz" \
      --output "$archive"
    tar -xzf "$archive" -C "$bin_dir" --strip-components=2 \
      "pandoc-$pandoc_version/bin/pandoc"
    chmod +x "$pandoc_bin"
    rm -f -- "$archive"
  fi
fi

if command -v tectonic >/dev/null 2>&1; then
  tectonic_bin="$(command -v tectonic)"
else
  tectonic_bin="$bin_dir/tectonic"
  if [[ ! -x "$tectonic_bin" ]]; then
    prepare_download
    echo "Baixando Tectonic $tectonic_version para .tools/ (somente na primeira execução)..."
    archive="$(mktemp "$tools_dir/tectonic.XXXXXX")"
    curl --fail --location --retry 2 --silent --show-error \
      "https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%40$tectonic_version/tectonic-$tectonic_version-x86_64-unknown-linux-musl.tar.gz" \
      --output "$archive"
    tar -xzf "$archive" -C "$bin_dir" tectonic
    chmod +x "$tectonic_bin"
    rm -f -- "$archive"
  fi
fi

echo 'Gerando slides.tex...'
"$pandoc_bin" slides.md --from markdown-auto_identifiers --to beamer --standalone \
  --syntax-definition template/gleam.xml \
  --metadata-file template/metadata.yml --metadata-file metadata-aula.yml \
  --template template/default.beamer -V mathspec -o slides.tex
echo 'Gerando slides.pdf (na primeira execução, o Tectonic também baixa fontes e pacotes)...'
"$tectonic_bin" --keep-logs slides.tex
echo "PDF atualizado: $PWD/slides.pdf"
