# Aula de avaliação da SHOW

Material preparado para Matheus Cenerini Jacomini apresentar o TCC **SHOW: uma biblioteca educativa para interfaces gráficas interativas no Sgleam**, orientado por Marco Aurélio Lopes Barbosa, aos estudantes de Programação Funcional da UEM.

A aula ocupa 13h30–15h10, com os dez minutos finais reservados à avaliação individual. A margem até 15h15 fica para atendimento. Os exemplos e exercícios assumem os conhecimentos das notas da disciplina, sem repetir uma introdução à linguagem.

## Arquivos

- `playground-local.zip`: playground compilado com executor HTTP real, TXT, exemplos e servidor Deno para ensaiar no notebook sem compilar.
- `aula-show.zip`: pacote completo do docente, com fontes, slides, gabaritos e instrumento.
- `materiais-alunos.zip`: enunciados, bases de exercícios, TXT e exemplos completos contador/texto, para distribuir à turma.
- `qr-avaliacao.png`: QR code do formulário de avaliação, utilizado no último slide.
- `slides.pdf`: apresentação para projetar, no template Pandoc/Beamer Metropolis da disciplina.
- `slides.md` e `metadata-aula.yml`: fontes editáveis da apresentação.
- `roteiro-docente.md`: horários, fala de abertura, condução, dicas e plano para atrasos.
- `alunos/enunciados.md`: requisitos e critérios de conclusão.
- `alunos/exercicio_1.gleam`, `exercicio_2.gleam` e `exercicio_3.gleam`: bases com foco em init/update/view; funções auxiliares prontas e poucos testes essenciais nos exercícios 1 e 2; exercício 3 sem testes automatizados.
- `codigos/contador.gleam` e `texto.gleam`: exemplos guiados completos com testes.
- `codigos/login.gleam`, `lista.gleam` e `efeitos.gleam`: gabaritos completos; login/lista mantêm apenas testes essenciais e efeitos é conferido no playground.
- `emails-existentes.txt`: conteúdo da lista externa servida por HTTP.
- `execucao-real.md`: preparação do playground, publicação do TXT e demonstração do exercício 3.
- `questionario-show.docx`: documento revisado para importação no Google Docs.
- `questionario.md`: conteúdo do instrumento em texto editável.
- `questionario-likert.md`: proposta mais recente de avaliação, com doze afirmações de 1 a 5, organizada a partir da referência do Sarcade. O DOCX e o Google Forms anteriores ainda contêm o instrumento inicial.
- `avaliacao-e-monografia.md`: protocolo de aplicação, análise e estrutura para redigir a avaliação depois da coleta.

## Ensaiar e executar

As interfaces devem ser executadas no Sgleam web compatível com a biblioteca deste repositório. Confirmar a versão publicada antes da aula; se necessário, usar o build local do SimpleCode. `main()` inicia a interface. O CLI verifica compilação e testes, mas não apresenta os controles como o ambiente web.

Para executar os testes no CLI, entrar na pasta do arquivo antes de chamar o comando. O caminho fornecido também forma o nome do módulo; por isso, não passar o caminho contendo `aula-tcc` ao sgleam.

```sh
cd docs/aula-tcc/codigos
sgleam test contador.gleam
sgleam test texto.gleam
sgleam test login.gleam
sgleam test lista.gleam
sgleam check efeitos.gleam
```

As bases dos exercícios 1 e 2 deixam init/update/view para os alunos; a base 3 reutiliza a interface anterior e deixa lacunas de tarefas, respostas e estados. Login contém três verificações (init e edição dos campos); lista contém cinco (init, inclusão, repetição e preservação). Efeitos não contém testes automatizados nem dependência de executor simulado: a conferência é feita no playground.

Disponibilizar contador/texto desde o início e os gabaritos dos exercícios somente na resolução coletiva. Para regenerar as bases preservando alterações nos gabaritos, executar `python3 apoio/preparar_codigos.py --bases`.

## Efeitos e escopo

A biblioteca local e o host local do SimpleCode oferecem execução HTTP real para GET/POST e espera. O exemplo de efeitos usa `app.run` e é conferido diretamente no playground. O TXT `emails-existentes.txt` é servido junto à página do playground, sem depender de um domínio externo.

A aula considera o playground publicado pelo orientador atualizado, mas a implementação local não publica automaticamente o site dele. Conferir a versão e o TXT antes da aula. Ver `execucao-real.md` para preparar e ensaiar o ambiente. O executor é sequencial no worker, com timeout de 10 segundos; a aplicação aguarda o pedido terminar para tratar novos eventos.

Os e-mails adicionados permanecem no modelo durante a sessão. Não existe persistência no disco nem após atualizar a página. As regras de nomes e domínios são simplificadas e estão explicitadas no enunciado.

## Gerar o PDF novamente

No Ubuntu/WSL, executar `bash gerar-slides.sh`. O script reutiliza Pandoc e Tectonic disponíveis no PATH; se estiverem ausentes, baixa os binários oficiais do Pandoc 3.5 e do Tectonic 0.15.0 para `.tools/bin/`, sem precisar de sudo. O download automático é para Linux x86_64 e requer `curl`, `tar` e internet. As ferramentas locais são reutilizadas nas próximas execuções e não entram no pacote ZIP.

No PowerShell, usar `./gerar-slides.ps1` com Pandoc e Tectonic previamente disponíveis; os parâmetros `-Pandoc` e `-Tectonic` aceitam caminhos absolutos. O primeiro uso do Tectonic também baixa os pacotes e fontes necessários. O template e a sintaxe Gleam foram copiados do repositório indicado em `template/`; a identidade desta aula é aplicada por `metadata-aula.yml`, e o peso normal dos títulos por `titulos.tex`.

## Google Docs e aplicação do questionário

O DOCX é a matriz do questionário. A entrega em Google Docs depende da importação nativa pela integração Google Drive. Depois da importação, conferir o acesso, criar um procedimento de cópia individual e inserir o link real no local de distribuição usado pela turma. O slide final orienta o acesso ao questionário distribuído pelo docente; não contém um link inventado.

O questionário tem contexto prévio, conclusão por exercício, oito itens de percepção, duas questões conceituais e três perguntas abertas. As instruções e a análise distinguem NA de resposta neutra e compreensão imediata de ganho de aprendizagem. O link não foi enviado aos estudantes e não há resultados coletados.

## Fontes e atribuição

Notas da disciplina e template: Marco A. L. Barbosa, [na-progfun](https://github.com/malbarbo/na-progfun), licença [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). Os slides adaptam esse template e seguem a mesma licença. A autoria dos conteúdos novos da oficina é de Matheus Cenerini Jacomini, que deve revisar o material antes de aplicá-lo.

Referência técnica principal: a versão local de `lib/sgleam/show`, `lib/sgleam/task.gleam`, os exemplos e `docs/pt-br/tasks.md`. O projeto de funções segue análise, definição de tipos, especificação, implementação, verificação e revisão, conforme as notas da disciplina.
