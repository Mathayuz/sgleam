# Aula de avaliação da SHOW

TCC: **SHOW: uma biblioteca educativa para interfaces gráficas interativas no Sgleam**. Autor: Matheus Cenerini Jacomini. Orientador: Marco Aurélio Lopes Barbosa. Público: estudantes de Programação Funcional da UEM que já conhecem o conteúdo das notas de aula. Duração: 13h30–15h10; margem de cinco minutos para atendimento depois da avaliação.

## Objetivos observáveis

Ao final, espera-se que o estudante consiga representar o estado de uma interface, associar eventos a mensagens, implementar transições em `update`, construir a `view`, especificar e testar as funções de inicialização e atualização e tratar uma resposta externa com sucesso ou falha. A aula também coleta a percepção dos estudantes sobre a SHOW. Uma oficina e um questionário de percepção, isoladamente, não demonstram ganho de aprendizagem nem superioridade sobre outra ferramenta.

## Cronograma e condução

| Horário | Minutos | Slides de conteúdo | Condução e evidência |
|---|---:|---|---|
| 13h30–13h38 | 8 | 1–4 | Apresentar autor, título, problema e proposta. Relacionar a World à SHOW em cerca de um minuto: estado, apresentação e transformação por funções. Abrir ambiente e executar exemplo pronto. Explicar a contribuição do questionário sem antecipar uma avaliação positiva. |
| 13h38–13h46 | 8 | 5–7 | Construir ciclo MVU e relacionar com o projeto de funções já estudado. Pedir que a turma identifique o estado de uma tela. |
| 13h46–13h55 | 9 | 8–11 | Contador: esboço, `Int`, mensagens, exemplos de update e view. Executar testes antes de clicar. |
| 13h55–14h05 | 10 | 12–15 | Texto: projetar `Caixa`, Model e Msg; prever saídas, testar combinações e só então executar a UI. |
| 14h05–14h23 | 18 | 16–18 | Exercício 1. Reservar 2 min para esboço e exemplos, 5 min para init/update e testes, 6 min para view e 5 min para resolução coletiva. |
| 14h23–14h38 | 15 | 19–21 | Exercício 2. Fazer 2 min de análise do modelo, 4 min de init/update e testes, 5 min de view e 4 min de resolução coletiva. |
| 14h38–14h48 | 10 | 22–25 | Explicar efeitos, tarefa e mensagem de resposta; demonstrar obtenção HTTP real e falha. |
| 14h48–15h00 | 12 | 26–28 | Exercício 3 com base pronta: 2 min de leitura, 7 min nas lacunas de init/update/view e conferência no playground, 3 min de resolução coletiva. |
| 15h00–15h10 | 10 | 29–30 | Projetar o último slide com QR code e manter silêncio para resposta individual. |

A contagem acima exclui a capa. Para localizar no PDF pelo rodapé, somar um aos números da tabela: o conteúdo 1 está na página 2, e a avaliação com QR code está na página 31 (último slide). O cronograma é um guia: a interação e a implementação têm prioridade sobre ler todos os slides.

## Preparação antes da aula

Disponibilizar `materiais-alunos.zip`, com enunciados, bases, TXT e os exemplos completos contador e texto. Manter os gabaritos login/lista/efeitos para a resolução coletiva, depois do tempo de tentativa de cada exercício. Os arquivos são autocontidos. As funções de domínio estão prontas nas três bases; os alunos concentram a escrita em init/update/view. Os tipos Model e Msg são fornecidos como apoio: pedir que a dupla justifique os campos e as mensagens após esboçar a tela. Nos exercícios 1 e 2, os alunos escrevem os componentes e callbacks na view; no terceiro, reutilizam a interface e completam os estados e a integração das tarefas.

Abrir o Sgleam web e confirmar que a versão carregada tem `sgleam/show/simple_app`, `sgleam/show/app`, `sgleam/show/radio_group` e a execução de tarefas HTTP. Se o site público estiver desatualizado, usar o build local do SimpleCode que acompanha este projeto. Os cinco programas foram compilados com o engine publicado em https://malbarbo.pro.br/sgleam/show/. Confirmar a disponibilidade do TXT antes da aula. Conferir editor, execução de `main()` e testes no ambiente da sala. No CLI, executar testes **dentro da pasta do arquivo**, pois o caminho informado também compõe o nome de módulo e a pasta `aula-tcc` contém hífen.

Testar projeção, acesso dos estudantes e compartilhamento do questionário. Disponibilizar uma cópia individual por respondente se ele for aplicado em Google Docs; um documento editável por toda a turma expõe respostas e permite sobrescritas. Google Docs é o instrumento solicitado; se depois for migrado para Google Forms, preservar exatamente as perguntas e escalas. Não enviar uma cópia pública editável para todos.

## Abertura sugerida

“Sou Matheus Cenerini Jacomini e desenvolvi, com orientação do professor Marco Aurélio Lopes Barbosa, a SHOW, uma biblioteca educativa para interfaces gráficas interativas no Sgleam. Hoje vamos usar os tipos, as listas e o projeto de funções que vocês já conhecem para construir interfaces. Começaremos com dois exemplos e depois faremos três exercícios. Ao final, convido vocês a relatar a experiência em um questionário. As dificuldades e críticas também são úteis para avaliar a biblioteca.”

Apresentar a proposta sem afirmar que a ferramenta já facilita a aprendizagem. A motivação didática é aproximar programação interativa do repertório funcional da turma. Não há monografia disponível neste workspace para confirmar objetivos formais, hipóteses ou contribuições além do título e do código; adaptar essa breve contextualização aos termos exatos do texto final.

## Como usar os exemplos

No contador, escrever primeiro o esboço e perguntar qual informação varia. `Int` é suficiente; não é necessário criar um registro sem motivo. Registrar o propósito de update e prever `0 -> -1`, pois negativos são permitidos. Implementar e executar os três testes; só depois mostrar a ligação de um botão com a mensagem. A view completa está no arquivo para evitar digitar os três botões durante a apresentação.

No texto, manter o valor original no Model. O resultado é derivado; se fosse guardado separadamente, cada alteração teria de atualizar os dois valores. O checkbox é independente da caixa; as três caixas são alternativas de um tipo. Testar as seis combinações e a string vazia. Pedir uma previsão antes de executar: `Gleam`, inversão ativa, maiúsculas resulta em `MAELG`. Mostrar que “nenhuma” significa nenhuma alteração de caixa, preservando a inversão quando marcada.

Para cada função de domínio, aplicar a sequência: análise, tipos, especificação com propósito/assinatura/exemplos, implementação, verificação e revisão. Esse processo está dentro das três etapas de projeto da aplicação; não é uma atividade separada no final. Os testes não provam a correção para todas as entradas. Para view, a checagem visual e de interação é suficiente nesta oficina; manter os testes dos exemplos guiados e apenas os exemplos essenciais de init/update nos exercícios 1 e 2. No exercício 3, conferir o comportamento na interface, sem apresentar testes de efeitos.

## Exercícios e apoio gradual

Exercício 1: os alunos implementam init, update e view. Login, validação e prévia já estão prontos e testados. Começar pelo propósito: init fornece nome vazio e domínio uem.br; update altera apenas o campo indicado; view constrói dois inputs e o texto da prévia. Os dois testes de update já partem de campos preenchidos para conferir preservação. Como apoio gradual, lembrar text_input.on_input e mostrar apenas um campo se necessário. A regra de oito caracteres é um requisito fornecido, não uma tarefa de manipulação de strings. Na resolução, o gabarito pode decompor os campos em helpers equivalentes à construção direta na view.

Exercício 2: a lista pertence ao Model e deve sobreviver à edição dos campos. Os alunos completam init/update/view; adicionar e cadastrar já estão implementadas. A mensagem Adicionar deve chamar cadastrar(model); as edições preservam a lista e limpam o aviso. Na view, associar o botão à mensagem, mostrar o aviso e transformar a lista em elementos de texto. Verificar a duplicação por testes de update e interação. Reservar os minutos finais para resolver junto com a turma.

Exercício 3: distribuir a base a todos, mesmo a quem não concluiu os anteriores. Carregar, ler_emails e cadastrar estão prontos. Os alunos ligam carregar() à inicialização e à nova tentativa; tratam Recebidos com sucesso ou falha em update; completam as condições de button.enabled e o texto dos estados na view. Os ramos de edição e inclusão, os componentes anteriores e o main com app.run estão fornecidos. O bloqueio existe também na regra de cadastro, independentemente do botão. Conferir carregamento, bloqueio de endereços reservados, inclusão e recuperação de falha no playground. Não gastar o tempo com implementação do parser.

## Preparação da execução HTTP real

A aula considera o playground publicado pelo orientador com o host e o engine atualizados. A implementação local já oferece executor real; a publicação no site é uma etapa externa e deve ser conferida antes da aula. Não presumir que a versão pública foi atualizada só porque o material foi adaptado.

`task.get` descreve o pedido, enquanto `app.run` usa o interpretador web para realizá-lo. O arquivo `codigos/efeitos.gleam` e a base 3 usam `emails-existentes.txt`, relativo à página do editor. O Makefile local do SimpleCode copia esse TXT para build e dist. Para publicar, incluir o TXT ao lado de sgleam.html. Confirmar o acesso à URL do arquivo e executar o gabarito no playground que a turma utilizará. Uma URL relativa dispensa CORS se ambos estiverem na mesma origem; para outro servidor, ele deve permitir a origem do playground.

Demonstração: executar o gabarito; tentar Ana/uem.br (reservado), Bia/uem.br (disponível) e novamente Bia (repetido). Depois, trocar a URL por `emails-inexistentes.txt` e reiniciar: deve aparecer Falhou com o cadastro bloqueado e a opção de tentar novamente. O botão repete a URL atual, portanto restaurar a URL correta e reiniciar para recuperar. Com servidor local, também é possível retirar e restaurar o TXT durante a demonstração, sem alterar o código. Não editar o arquivo publicado do orientador sem combinar previamente.

O host faz HTTP síncrono no worker, com timeout de 10 segundos por pedido; a página continua responsiva, mas a aplicação só trata novos eventos quando ele termina. Stop pode aguardar o fim/timeout do pedido. O estado Carregando é apresentado antes da operação; em uma rede rápida pode durar pouco. Não confundir carregar conteúdo na aplicação com salvar um arquivo no disco.

O exercício 3 não inclui testes automatizados: apresentar o ciclo real e conferir os resultados na interface. O guia `execucao-real.md` contém os passos de preparação local e publicação.

## O que observar sem interromper o trabalho

Em cada atividade, anotar horário de início/fim, número de duplas que começaram/concluíram, tipos de dúvida e intervenções necessárias. Diferenciar dúvidas de Gleam, de MVU, da API SHOW, dos requisitos e do ambiente. Se uma dupla muda de base ou recebe o gabarito, registrar esse apoio. Execução com ajuda não equivale a conclusão autônoma.

Não inferir desempenho individual de uma atividade em dupla. Não coletar nome, matrícula ou e-mail pessoal no questionário. Caso sejam usados registros de desempenho vinculados a pessoas ou dados pessoais, combinar previamente o procedimento com o orientador e com o protocolo aplicável ao TCC. O texto de participação do questionário é um convite informativo, não substitui eventual documentação institucional de consentimento.

## Se houver atraso

Às 14h23, liberar a base do exercício 2 a quem precisar. Às 14h38, interromper o exercício 2 para garantir a explicação de efeitos. Às 14h48, usar a base do exercício 3 pronta; pedir as lacunas de integração em init, update e view. Às 15h00, iniciar a avaliação mesmo que nem todos tenham concluído. O questionário oferece “não realizei” e pergunta o nível de ajuda. Usar 15h10–15h15 para dúvidas ou uma demonstração final, sem reduzir o tempo reservado às respostas.

## Depois da aula

Guardar versão dos materiais, data, modalidade de execução efetivamente usada (real ou alternativa simulada), quantidade de presentes e respostas válidas. Separar o documento vazio dos preenchidos. Não compartilhar respostas entre participantes. Analisar os dados conforme `avaliacao-e-monografia.md`; atualizar a monografia apenas com resultados efetivamente coletados, incluindo dificuldades, respostas omitidas e limitações.
