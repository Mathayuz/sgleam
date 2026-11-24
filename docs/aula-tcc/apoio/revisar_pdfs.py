from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
from pypdf import PdfReader

root = Path(__file__).resolve().parents[1]
qa = root / 'apoio' / 'qa'
pdf = PdfReader(root / 'slides.pdf')
print(f'Slides: {len(pdf.pages)} páginas; dimensões {pdf.pages[0].mediabox}')
for i, page in enumerate(pdf.pages, 1):
    content = page.extract_text()
    print(f'{i:02}: {len(content)} caracteres; {content.splitlines()[0] if content else "VAZIA"}')
images = sorted(qa.glob('slide-*.png'))
for offset in range(0, len(images), 6):
    sheet = Image.new('RGB', (1600, 1440), '#dedede')
    for pos, path in enumerate(images[offset:offset+6]):
        im = Image.open(path).convert('RGB')
        im.thumbnail((780, 440))
        x, y = 10 + (pos % 2) * 800, 30 + (pos // 2) * 480
        sheet.paste(im, (x, y))
        ImageDraw.Draw(sheet).text((x, y-20), f'Página {offset+pos+1}', fill='black')
    sheet.save(qa / f'contato-{offset//6+1}.png')
