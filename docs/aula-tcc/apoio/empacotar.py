from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
app = root.parents[2] / 'simplecode'
assets = ['sgleam.html', 'sgleam.wasm', 'emails-existentes.txt']
if all((app / 'dist' / name).is_file() for name in assets) and (app / 'tools/servir-aula.ts').is_file():
    with ZipFile(root / 'playground-local.zip', 'w', ZIP_DEFLATED) as z:
        for name in assets:
            z.write(app / 'dist' / name, Path('playground-show/dist') / name)
        z.write(app / 'tools/servir-aula.ts', 'playground-show/servir-aula.ts')
        for name in ['contador', 'texto', 'login', 'lista', 'efeitos']:
            z.write(root / 'codigos' / f'{name}.gleam', f'playground-show/exemplos/{name}.gleam')
        z.writestr('playground-show/LEIA-ME.txt',
            'Com Deno instalado, entre nesta pasta e execute:\n'
            'deno run --allow-read --allow-net servir-aula.ts dist\n\n'
            'Abra http://localhost:8000/sgleam.html\n'
            'Carregue um arquivo de exemplos e execute main().\n'
            'O TXT e o executor HTTP real ja estao incluidos.\n'
            'Sem compilacao, WSL ou download de dependencias.\n'
            'Este modo local nao oferece login ou Google Drive.\n'
            'Mantenha o terminal aberto; Ctrl+C encerra o servidor.\n')
with ZipFile(root / 'materiais-alunos.zip', 'w', ZIP_DEFLATED) as z:
    for file in sorted((root / 'alunos').iterdir()):
        if file.is_file():
            z.write(file, file.name)
    z.write(root / 'emails-existentes.txt', 'emails-existentes.txt')
    for name in ['contador.gleam', 'texto.gleam']:
        z.write(root / 'codigos' / name, Path('exemplos') / name)

skip = {'.aux', '.log', '.nav', '.toc', '.vrb', '.snm'}
with ZipFile(root / 'aula-show.zip', 'w', ZIP_DEFLATED) as z:
    for file in sorted(root.rglob('*')):
        relative = file.relative_to(root)
        if not file.is_file() or 'qa' in relative.parts or '__pycache__' in relative.parts or '.tools' in relative.parts:
            continue
        if file.name in {'aula-show.zip', 'slides.tex'} or file.suffix in skip:
            continue
        z.write(file, Path('aula-show') / relative)
for name in ['materiais-alunos.zip', 'aula-show.zip', 'playground-local.zip']:
    if not (root / name).is_file():
        continue
    with ZipFile(root / name) as z:
        assert z.testzip() is None
        print(f'{name}: {len(z.namelist())} arquivos; {(root / name).stat().st_size} bytes')
