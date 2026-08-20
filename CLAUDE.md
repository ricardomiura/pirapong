# CLAUDE.md — instruções para o Claude Code

Você está no repositório do **Pirapong**, o controle de fila da mesa de tênis de mesa. No ar em **www.pirapong.com.br**.

## Resumo
App web de celular com duas telas, em abas: a **fila** da mesa no formato *"vencedor fica na mesa"* (`#/`) e o **torneio** de grupos + mata-mata (`#/torneio`). Qualquer pessoa abre o site, põe o nome na fila ou no torneio e marca quem venceu; todos os aparelhos atualizam ao vivo. Sem login para jogar — a confiança é da comunidade. Só o organizador do torneio se identifica.

## Stack e convenções (importante)
- **Um único arquivo `index.html`** com HTML + CSS + JS inline. **Sem framework, sem build.** É decisão deliberada — não introduza React/Vue/bundler sem o dono pedir.
- Backend: **Supabase** (Postgres) via `supabase-js` v2 importado do CDN (`esm.sh`).
- Interface toda em **português do Brasil**.
- A chave **publishable** do Supabase fica no front (é pública). **NUNCA** coloque a `service_role` key no frontend.
- Fontes: Oswald (títulos) + Inter (corpo), via Google Fonts.
- Paleta: verde-mesa `#123f31` / feltro `#1a5641` / bolinha laranja `#ff6a2b`.

## Regras do jogo (estão no JS, constante `CAP`)
- `CAP = 2` — máximo de partidas seguidas na mesa.
- O perdedor **sempre** sai e vai para o fim da fila.
- O vencedor que bate o `CAP` sai também, **mesmo vencendo**, e volta para o fim da fila.
- `fillSlots()` puxa da fila para qualquer lado vazio; quem entra zera o contador.
- Os "pips" mostram as vitórias seguidas, com aviso *"última se vencer"* na penúltima.

## Backend (Supabase)
- Projeto: `Pirapong` · ref `zjgrjzvjkufevqxtqnhq` · região `us-east-1`
- URL: `https://zjgrjzvjkufevqxtqnhq.supabase.co`
- Publishable key: `sb_publishable_YxP8ZanXuCnruNc0QpUP8g_MCZrxtac`
- Uma tabela só: `queue_state`, com **uma única linha** (`id = 1`). A fila inteira é o JSON da coluna `state`:
  ```json
  { "playing": ["Nome A", "Nome B"], "plays": [1, 0], "queue": ["Nome C"] }
  ```
- Schema e RLS em `supabase/schema.sql` (já aplicado no projeto).
- Realtime: canal `queue-updates` escutando `UPDATE` em `queue_state`.

## Aviso sobre o RLS
O RLS está **ligado mas totalmente aberto** (SELECT e UPDATE liberados para `public`, condição `true`). O comentário no `index.html` diz "protegida pelo RLS" — isso é impreciso: qualquer um pode sobrescrever a fila. É aceitável para o caso de uso, mas **não é segurança**. Se virar problema, trocar por uma RPC que só aceite mutações válidas.

## Torneio (grupos + mata-mata)
Segunda tela do app, em `#/torneio`. Roteador por hash dentro do próprio `index.html` (mesmo padrão do `piracanga-app`); a fila continua funcionando em `#/`.

- **Formato:** todos contra todos dentro do grupo, passam os 2 primeiros, depois mata-mata até o campeão.
- **Chaveamento** (dimensionado para até 20 inscritos, que é o teto esperado): `qtdGrupos()` dá 1 grupo até 5 inscritos, 2 até 9, 3 até 14 e 4 daí em diante — sempre grupos de 3 a 5. Os classificados entram numa chave de potência de 2; sobrando vaga, vira *bye* para os primeiros de melhor campanha. Um passe de reparo evita que gente do mesmo grupo se reencontre logo na estreia.
- **Placar:** grava só o vencedor (`partidas.vencedor`). As colunas `sets_a`/`sets_b` existem e estão sem uso — dá para ligar placar em sets sem migração nova.
- **Desempate:** mini-tabela, ou seja, vitórias contando só os jogos entre os empatados. Com dois, isso é o confronto direto; com três ou mais, revela ciclos (A ganha de B, B de C, C de A). Quando o corte da 2ª vaga cai dentro de um empate que a mini-tabela não resolve, a tela **avisa** em vez de fingir uma ordem — é consequência de gravar só o vencedor.
- **Classificação nunca é gravada:** `classificacao()` calcula na hora a partir das partidas, então não existe estado dessincronizado.
- **Login:** só o organizador precisa entrar, com **Google** (`signInWithOAuth`), igual ao `piracanga-app`. Inscrever-se e acompanhar não pedem login de propósito.
- **Datas:** não usam `<input type="date">` — no desktop ele vira um ícone minúsculo e no celular esconde a data atrás de um popup. No lugar, um calendário embutido (`campoData`/`gradeHTML`) com atalhos Hoje/Amanhã/Sábado, dias passados bloqueados e teto: "inscrições até" nunca passa da data do torneio, e puxar o torneio para antes do prazo corrige o prazo sozinho. As datas ficam no objeto `escolhido`, não no DOM, e `pintarCalendario()` repinta só um campo — redesenhar o formulário inteiro apagaria o nome já digitado.
- Schema, RLS e realtime em `supabase/torneio.sql`.

> **Pré-requisito ainda não feito:** o provedor Google precisa ser habilitado em Authentication → Providers no painel do Supabase (Client ID + Secret do Google Cloud Console) e `https://www.pirapong.com.br` liberado nas URLs de redirect. **Sem isso o botão "Entrar com Google" não funciona** — mas inscrição e visualização já funcionam.

### Testes
Não há suíte no repo (o app é um arquivo só, sem build). Os dois testes que valeram a pena foram escritos como scripts avulsos de Node que **extraem as funções reais do `index.html`** e as rodam contra cenários montados à mão — um para a matemática do chaveamento (4 a 20 inscritos) e outro para a classificação (empate de dois, ciclo de três, grupo pela metade). Se for mexer em `classificacao()`, `empateNaFronteira()` ou `gerarChave()`, vale refazer esse tipo de checagem: foi assim que apareceu o bug do ciclo de três.

## Rodar
Não tem build. Abra `index.html` no navegador. Para o backend responder, precisa de internet.

## Deploy
Cloudflare **Pages**, projeto `pirapong`, **conectado por integração Git a este repositório**. Não há build e não se usa wrangler: **todo `push` na `main` publica sozinho**. No ar em `https://www.pirapong.com.br`; URL de teste `https://pirapong.pages.dev`.

O diretório servido é a **raiz do repositório**. Isso tem uma consequência importante: **qualquer arquivo commitado na raiz vira URL pública** — este `CLAUDE.md`, por exemplo, é acessível em `/CLAUDE.md`. Nunca commite nada aqui que não possa ser lido por qualquer pessoa. Se um dia isso incomodar, a saída é mover o site para uma subpasta e apontar o *build output directory* do Pages para ela (mexida no painel da Cloudflare).

Rotas desconhecidas caem no `index.html` (fallback de página única).

## Nota sobre continuidade
O repositório nasceu de uploads pela web do GitHub ("Add files via upload"). Em 19/08/2026 o projeto ganhou estrutura local: o histórico do GitHub foi adotado como fonte de verdade e o `index.html` foi conferido byte-a-byte contra a produção (18.996 bytes, idênticos). O arquivo é gravado em **LF** no repositório; no Windows o checkout vira CRLF, o que é normal — não tente "corrigir" isso.
