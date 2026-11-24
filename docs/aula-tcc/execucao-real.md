# Execução HTTP real na aula

A oficina usa init/update/view e Task sem misturar a regra da aplicação com o acesso à rede. `task.get(url)` descreve o GET. `app.run` usa o interpretador web, que pede ao host do SimpleCode a requisição real. O resultado volta à continuação como `Result(String, task.HttpError)` e produz `Recebidos`, tratado por update.

## O que precisa estar publicado

O playground precisa incluir, na mesma versão:

- Engine Sgleam com `sgleam/task/web` e os imports HTTP do WASM.
- Host SimpleCode com o transporte HTTP no worker.
- `emails-existentes.txt` ao lado da página `sgleam.html`, com um endereço por linha.

Os três itens estão preparados nos repositórios locais. A publicação no site do orientador ainda precisa ser feita por ele; este material não afirma que o site já foi atualizado. Servir o TXT na mesma origem evita configuração adicional de CORS. Se ele for hospedado em outro domínio, esse servidor deve permitir a origem do playground.

## Preparar no computador que compila

Na cópia local do SimpleCode, o submódulo `engines/sgleam` também precisa conter as mudanças do executor. A cópia deste workspace já foi sincronizada nos arquivos correspondentes, preservando as outras mudanças locais.

```sh
cd ~/repositorios_github/simplecode
CARGO_BUILD_JOBS=2 make dist/sgleam.html dist/sgleam.wasm dist/emails-existentes.txt
```

Esse alvo gera somente o playground Sgleam necessário à aula. O primeiro build exige as dependências do projeto e pode demorar. Não é necessário repetir a compilação no notebook.

## Ensaiar sem compilar no notebook

O pacote `playground-local.zip` já inclui a versão compilada, o TXT, os cinco exemplos e `servir-aula.ts`. Basta extrair, entrar na pasta `playground-show` e executar o comando abaixo. Não é necessário copiar arquivos manualmente nesse caso.

Copie a pasta `dist` gerada e `tools/servir-aula.ts` para o notebook. Com Deno instalado, entre na pasta que contém `dist` e execute:

```sh
deno run --allow-read --allow-net servir-aula.ts dist
```

Se estiver usando o repositório completo, o caminho é `tools/servir-aula.ts`. Esse servidor não baixa dependências externas e envia os headers de isolamento necessários ao SharedArrayBuffer do playground. Um servidor estático genérico sem esses headers pode impedir o funcionamento do worker. Abra `http://localhost:8000/sgleam.html` e mantenha o terminal aberto. Pode executar no Windows, sem WSL.

O modo estático oferece editor, execução e HTTP do programa; login e integração com Google Drive dependem do servidor próprio do SimpleCode. Na aula, usar o playground publicado e confirmado pelo orientador ou essa cópia local ensaiada.

## Demonstração do exercício 3

1. Abra `codigos/efeitos.gleam` no playground e execute `main()`.
2. `init` começa em Carregando e solicita `emails-existentes.txt`. `view` bloqueia Adicionar enquanto a lista está indisponível.
3. `Recebidos(Ok(conteudo))` guarda a lista, mostra seus endereços em “E-mails existentes no TXT” e libera o cadastro. A seção “Cadastrados nesta sessão” mostra somente os novos endereços incluídos pelo usuário.
4. Ana/uem.br deve ser rejeitado, porque `ana@uem.br` está no TXT.
5. Bia/uem.br deve ser incluído; uma segunda inclusão deve ser rejeitada.
6. Para mostrar falha HTTP, altere a URL para `emails-inexistentes.txt` e reinicie. O programa deve mostrar a falha, bloquear Adicionar e permitir nova tentativa.
7. A nova tentativa repete a URL configurada. Para recuperar, restaure `emails-existentes.txt` e reinicie. Em um servidor local, também pode retirar/restaurar o TXT enquanto o programa roda.

Baixar o TXT significa obter seu conteúdo para a aplicação; não salvar um arquivo no disco do aluno. A lista local de cadastrados permanece somente durante a sessão.

## Conferência e limites

O exercício 3 não contém testes automatizados. Confiram o fluxo de sucesso, bloqueio de duplicação, falha e recuperação diretamente no playground. No CLI nativo não há transporte HTTP, portanto a execução da interface ocorre no playground.

O HTTP é sequencial no worker, com timeout de 10 segundos. A página não fica bloqueada, mas o programa aguarda a operação antes de processar novos eventos; Stop pode aguardar a resposta ou o timeout. Uma resposta rápida pode tornar Carregando breve. As regras de CORS e conteúdo misto do navegador permanecem válidas. Falhas de rede e CORS chegam como NetworkError; resposta não 2xx chega como BadStatus.

Antes da aula, execute o gabarito na URL publicada que os alunos usarão. Registre no protocolo a versão efetivamente utilizada e qualquer alternativa local/simulada, sem antecipar os resultados da avaliação.
