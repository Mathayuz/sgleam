param(
  [string]$Pandoc = 'pandoc',
  [string]$Tectonic = 'tectonic'
)
$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
  & $Pandoc slides.md --from markdown-auto_identifiers --to beamer --standalone --syntax-definition template/gleam.xml --metadata-file template/metadata.yml --metadata-file metadata-aula.yml --template template/default.beamer -V mathspec -o slides.tex
  if ($LASTEXITCODE -ne 0) { throw 'Falha na geração do TeX.' }
  & $Tectonic --keep-logs slides.tex
  if ($LASTEXITCODE -ne 0) { throw 'Falha na geração do PDF.' }
} finally {
  Pop-Location
}
