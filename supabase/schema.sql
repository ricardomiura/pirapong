-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Pirapong — schema do banco (Supabase / Postgres)             ║
-- ║  Projeto: Pirapong · ref zjgrjzvjkufevqxtqnhq · us-east-1     ║
-- ╚══════════════════════════════════════════════════════════════╝
-- Este arquivo reflete o que JÁ ESTÁ APLICADO em produção.
-- Foi reconstruído a partir do banco no ar em 19/08/2026.

-- ── A fila inteira mora numa única linha (id = 1) ──────────────
-- O estado é um JSON só, reescrito por completo a cada jogada.
-- Simples de propósito: a mesa é uma só, não há concorrência real.
create table if not exists public.queue_state (
  id         integer primary key default 1,
  state      jsonb   not null default '{"plays": [0, 0], "queue": [], "playing": [null, null]}'::jsonb,
  updated_at timestamptz not null default now(),
  constraint linha_unica check (id = 1)
);

-- Garante que a linha existe.
insert into public.queue_state (id) values (1) on conflict (id) do nothing;

-- ── RLS ────────────────────────────────────────────────────────
-- ATENÇÃO: está ligado, porém TOTALMENTE ABERTO. Qualquer pessoa
-- com a URL lê e sobrescreve o estado. É intencional (todo mundo
-- precisa poder entrar na fila sem login), não é uma proteção.
-- Se um dia alguém zoar a fila de fora, trocar por uma RPC que só
-- aceite mutações válidas (entrar / vencer / sair).
alter table public.queue_state enable row level security;

create policy "todos leem a fila"
  on public.queue_state for select
  to public
  using (true);

create policy "todos atualizam a fila"
  on public.queue_state for update
  to public
  using (true)
  with check (true);

-- ── Realtime ───────────────────────────────────────────────────
-- O front escuta UPDATE nesta tabela (canal 'queue-updates') para
-- todos os celulares atualizarem ao vivo, sem refresh.
alter publication supabase_realtime add table public.queue_state;
