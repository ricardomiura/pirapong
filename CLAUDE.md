# CLAUDE.md — instruções para o Claude Code

Você está no repositório do **Pirapong**, o controle de fila da mesa de tênis de mesa. No ar em **www.pirapong.com.br**.

## Resumo
App web de celular que gerencia a fila da mesa no formato *"vencedor fica na mesa"*. Qualquer pessoa abre o site, põe o nome na fila e marca quem venceu; todos os aparelhos atualizam ao vivo. Sem login, sem cadastro — a confiança é da comunidade.

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

## Rodar
Não tem build. Abra `index.html` no navegador. Para o backend responder, precisa de internet.

## Deploy
Cloudflare **Pages**, projeto `pirapong`, **conectado por integração Git a este repositório**. Não há build e não se usa wrangler: **todo `push` na `main` publica sozinho**. No ar em `https://www.pirapong.com.br`; URL de teste `https://pirapong.pages.dev`.

O diretório servido é a **raiz do repositório**. Isso tem uma consequência importante: **qualquer arquivo commitado na raiz vira URL pública** — este `CLAUDE.md`, por exemplo, é acessível em `/CLAUDE.md`. Nunca commite nada aqui que não possa ser lido por qualquer pessoa. Se um dia isso incomodar, a saída é mover o site para uma subpasta e apontar o *build output directory* do Pages para ela (mexida no painel da Cloudflare).

Rotas desconhecidas caem no `index.html` (fallback de página única).

## Nota sobre continuidade
O repositório nasceu de uploads pela web do GitHub ("Add files via upload"). Em 19/08/2026 o projeto ganhou estrutura local: o histórico do GitHub foi adotado como fonte de verdade e o `index.html` foi conferido byte-a-byte contra a produção (18.996 bytes, idênticos). O arquivo é gravado em **LF** no repositório; no Windows o checkout vira CRLF, o que é normal — não tente "corrigir" isso.
