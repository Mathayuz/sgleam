from pathlib import Path
from docx import Document
from docx.shared import Cm, Pt, RGBColor
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

ROOT = Path(__file__).resolve().parents[1]
doc = Document()
sec = doc.sections[0]
sec.page_width, sec.page_height = Cm(21), Cm(29.7)
sec.top_margin = sec.bottom_margin = Cm(1.65)
sec.left_margin = sec.right_margin = Cm(1.8)
for name in ['Normal', 'Title', 'Subtitle', 'Heading 1', 'Heading 2']:
    style = doc.styles[name]
    style.font.name = 'Calibri'
    style.font.color.rgb = RGBColor(0, 0, 0)
    style.font.size = Pt(10.5)
    style.paragraph_format.space_after = Pt(6)
    style.paragraph_format.line_spacing = 1.04
doc.styles['Title'].font.size = Pt(21)
doc.styles['Heading 1'].font.size = Pt(14)
doc.styles['Heading 1'].paragraph_format.space_before = Pt(8)
doc.styles['Heading 2'].font.size = Pt(11)

def p(text='', bold=False):
    para = doc.add_paragraph()
    run = para.add_run(text)
    run.bold = bold
    return para

def question(text, options):
    p(text, True)
    for option in options:
        para = p('( ) ' + option)
        para.paragraph_format.space_after = Pt(3)

def table(headers, rows, widths):
    t = doc.add_table(rows=1, cols=len(headers))
    t.autofit = False
    for column, width in zip(t.columns, widths):
        column.width = Cm(width)
    for c, label, width in zip(t.rows[0].cells, headers, widths):
        c.text, c.width = label, Cm(width)
        shading = OxmlElement('w:shd')
        shading.set(qn('w:fill'), 'EAEAEA')
        c._tc.get_or_add_tcPr().append(shading)
        for run in c.paragraphs[0].runs:
            run.bold = True
    for row in rows:
        cells = t.add_row().cells
        for cell, text, width in zip(cells, row, widths):
            cell.text, cell.width = text, Cm(width)
        cant = OxmlElement('w:cantSplit')
        t.rows[-1]._tr.get_or_add_trPr().append(cant)
    for row in t.rows:
        for cell in row.cells:
            for para in cell.paragraphs:
                para.paragraph_format.space_after = Pt(5)
                para.paragraph_format.space_before = Pt(4)
                for run in para.runs:
                    run.font.size = Pt(10)
    doc.add_paragraph().paragraph_format.space_after = Pt(0)
    return t

doc.add_paragraph('Avaliação da experiência com a SHOW', 'Title')
p('TCC: SHOW: uma biblioteca educativa para interfaces gráficas interativas no Sgleam.', True)
p('Matheus Cenerini Jacomini\nOrientador: Marco Aurélio Lopes Barbosa\nUniversidade Estadual de Maringá')
p('Responda individualmente, considerando sua experiência durante a oficina. O preenchimento leva aproximadamente 8 a 10 minutos. Queremos conhecer facilidades e dificuldades de uso da biblioteca.')
p('Sua participação é voluntária. Você pode não responder ou deixar perguntas em branco. Não informe nome, matrícula, e-mail pessoal ou informações que identifiquem colegas. As respostas autorizadas serão analisadas em conjunto e poderão ser usadas na monografia e na apresentação do TCC. Comentários eventualmente citados serão apresentados sem identificação.')
p('Você autoriza a utilização das suas respostas para essa finalidade?', True)
p('( ) Sim.    ( ) Não. Se marcar Não, encerre o preenchimento.')
doc.add_heading('Experiência anterior e atividades', 1)
question('1. Antes desta oficina, como você avaliava sua experiência com Gleam ou Sgleam?', [
    'Nenhuma.', 'Fiz apenas os exemplos das aulas.',
    'Resolvi exercícios com alguma autonomia.',
    'Desenvolvi programas além dos exercícios da disciplina.',
])
question('2. Antes desta oficina, você já tinha criado interfaces gráficas com campos e botões?', [
    'Não.', 'Sim, apenas seguindo exemplos.', 'Sim, com alguma autonomia.',
])
p('3. Até onde sua dupla conseguiu chegar em cada exercício?', True)
p('N = não iniciamos; P = iniciamos, mas não concluímos; A = concluímos com ajuda do docente ou de outra dupla; D = concluímos na própria dupla. Consultar enunciado e base é permitido em todas as alternativas. Concluir significa atender aos requisitos e executar os testes. Marque uma opção por linha.')
table(['Exercício', 'N', 'P', 'A', 'D'], [
    ['1 Gerador de login e prévia', '( )', '( )', '( )', '( )'],
    ['2 Lista sem repetição', '( )', '( )', '( )', '( )'],
    ['3 Lista externa simulada', '( )', '( )', '( )', '( )'],
], [11.8, 1.4, 1.4, 1.4, 1.4])

doc.add_page_break()
doc.add_heading('Sua experiência com a biblioteca', 1)
p('Para cada afirmação, registre o número correspondente na coluna Resposta. Use NA se não realizou ou não tem condições de avaliar. NA não significa resposta neutra.')
p('1 Discordo totalmente · 2 Discordo parcialmente\n3 Nem concordo nem discordo · 4 Concordo parcialmente\n5 Concordo totalmente · NA Não realizei ou não posso avaliar')
statements = [
    'Consegui identificar as informações necessárias no Model.',
    'Consegui representar os eventos da interface usando Msg.',
    'Consegui definir as mudanças de estado na função update.',
    'Consegui construir ou adaptar a interface na função view.',
    'Os nomes das funções dos componentes ajudaram a entender como utilizá-los.',
    'Consegui escrever ou adaptar testes para as regras da aplicação.',
    'Consegui entender o papel da Task no tratamento da lista externa.',
    'O material fornecido foi suficiente para eu avançar nos exercícios.',
]
table(['Item', 'Afirmação', 'Resposta'], [
    [str(n), text, '____'] for n, text in enumerate(statements, 4)
], [1.2, 13.0, 3.2])
doc.add_heading('Duas situações da aplicação', 1)
p('Estas perguntas ajudam a interpretar a experiência relatada. Não são uma prova. Se não souber, marque a alternativa correspondente.')
question('12. A aplicação solicita uma lista externa. Qual alternativa descreve o papel de update neste exemplo?', [
    'A. update precisa obter diretamente o conteúdo da rede antes de produzir qualquer valor.',
    'B. update pode produzir um modelo e a descrição de uma tarefa; a resposta chega como uma nova mensagem.',
    'C. A função view precisa modificar o modelo assim que o download termina.',
    'D. Não sei responder.',
])
question('13. O pedido da lista de e-mails falhou. Como o cadastro deve se comportar segundo o requisito do exercício 3?', [
    'A. Cadastrar normalmente, considerando que não existem e-mails reservados.',
    'B. Apagar a lista local e cadastrar o endereço solicitado.',
    'C. Impedir novas inclusões até obter a lista e permitir uma nova tentativa.',
    'D. Não sei responder.',
])

doc.add_page_break()
doc.add_heading('Comentários sobre a experiência', 1)
p('Descreva situações concretas sempre que possível. Você pode deixar qualquer resposta em branco.')
for title in [
    '14. Qual foi a principal dificuldade? Se possível, indique o exercício e o que você tentou fazer.',
    '15. O que mais ajudou você a realizar as atividades?',
    '16. Se pudesse mudar uma coisa na SHOW ou no material da oficina, o que mudaria?',
]:
    p(title, True)
    p('Resposta:')
    for _ in range(3):
        para = p('________________________________________________________________________')
        para.paragraph_format.space_after = Pt(8)
p('Obrigado pela participação.')
p('Este instrumento foi elaborado para esta avaliação. Não é uma escala padronizada ou validada de usabilidade.')

doc.core_properties.title = 'Avaliação da experiência com a SHOW'
doc.core_properties.author = 'Matheus Cenerini Jacomini'
doc.core_properties.subject = 'Questionário da oficina de avaliação do TCC'
out = ROOT / 'questionario-show.docx'
doc.save(out)
print(out)
