-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Pirapong — torneio (grupos + mata-mata)                      ║
-- ╚══════════════════════════════════════════════════════════════╝
-- Aplicado em 19/08/2026 como a migração `torneio_grupos_e_mata_mata`.
-- Leitura pública (qualquer um acompanha sem logar).
-- Gestão (criar, sortear, lançar resultado) só do organizador autenticado.

create table if not exists public.torneios (
  id             uuid primary key default gen_random_uuid(),
  nome           text not null,
  data           date,
  inscricoes_ate timestamptz,
  status         text not null default 'inscricoes'
                 check (status in ('inscricoes','grupos','mata_mata','encerrado')),
  organizador    uuid not null references auth.users(id) on delete cascade,
  criado_em      timestamptz not null default now()
);

create table if not exists public.inscricoes (
  id         uuid primary key default gen_random_uuid(),
  torneio_id uuid not null references public.torneios(id) on delete cascade,
  nome       text not null check (length(trim(nome)) between 1 and 24),
  grupo      text,                       -- 'A'..'D', preenchido no sorteio
  criado_em  timestamptz not null default now()
);
create unique index if not exists inscricoes_nome_unico
  on public.inscricoes (torneio_id, lower(nome));
create index if not exists inscricoes_por_torneio on public.inscricoes (torneio_id);

create table if not exists public.partidas (
  id         uuid primary key default gen_random_uuid(),
  torneio_id uuid not null references public.torneios(id) on delete cascade,
  fase       text not null check (fase in ('grupo','oitavas','quartas','semi','final','terceiro')),
  grupo      text,
  ordem      integer not null default 0, -- posição na fase; define a árvore da chave
  jogador_a  uuid references public.inscricoes(id) on delete cascade,
  jogador_b  uuid references public.inscricoes(id) on delete cascade,
  vencedor   uuid references public.inscricoes(id) on delete cascade,
  -- Reservados: hoje só gravamos o vencedor, mas o placar em sets cabe aqui
  -- sem migração nova, se o desempate por confronto direto não bastar.
  sets_a     smallint,
  sets_b     smallint,
  criado_em  timestamptz not null default now()
);
create index if not exists partidas_por_torneio on public.partidas (torneio_id, fase, ordem);

alter table public.torneios   enable row level security;
alter table public.inscricoes enable row level security;
alter table public.partidas   enable row level security;

-- ── Leitura: livre ───────────────────────────────────────────────
create policy "torneios leitura publica"   on public.torneios   for select to public using (true);
create policy "inscricoes leitura publica" on public.inscricoes for select to public using (true);
create policy "partidas leitura publica"   on public.partidas   for select to public using (true);

-- ── Torneio: só o organizador dono ───────────────────────────────
create policy "torneio criado por autenticado" on public.torneios
  for insert to authenticated with check (organizador = auth.uid());
create policy "torneio editado pelo dono" on public.torneios
  for update to authenticated using (organizador = auth.uid()) with check (organizador = auth.uid());
create policy "torneio apagado pelo dono" on public.torneios
  for delete to authenticated using (organizador = auth.uid());

-- ── Inscrição: aberta, enquanto o prazo está de pé ───────────────
-- Não exige login de propósito: entrar num torneio do Cantim não
-- deve pedir conta Google.
create policy "qualquer um se inscreve" on public.inscricoes
  for insert to public with check (
    exists (select 1 from public.torneios t where t.id = torneio_id and t.status = 'inscricoes'));
create policy "sai da lista antes do sorteio" on public.inscricoes
  for delete to public using (
    exists (select 1 from public.torneios t where t.id = torneio_id and t.status = 'inscricoes'));
create policy "organizador mexe nos inscritos" on public.inscricoes
  for update to authenticated using (
    exists (select 1 from public.torneios t where t.id = torneio_id and t.organizador = auth.uid()))
  with check (
    exists (select 1 from public.torneios t where t.id = torneio_id and t.organizador = auth.uid()));
create policy "organizador remove inscrito" on public.inscricoes
  for delete to authenticated using (
    exists (select 1 from public.torneios t where t.id = torneio_id and t.organizador = auth.uid()));

-- ── Partidas: só o organizador ───────────────────────────────────
create policy "organizador cria partidas" on public.partidas
  for insert to authenticated with check (
    exists (select 1 from public.torneios t where t.id = torneio_id and t.organizador = auth.uid()));
create policy "organizador lanca resultado" on public.partidas
  for update to authenticated using (
    exists (select 1 from public.torneios t where t.id = torneio_id and t.organizador = auth.uid()))
  with check (
    exists (select 1 from public.torneios t where t.id = torneio_id and t.organizador = auth.uid()));
create policy "organizador apaga partidas" on public.partidas
  for delete to authenticated using (
    exists (select 1 from public.torneios t where t.id = torneio_id and t.organizador = auth.uid()));

-- ── Realtime ─────────────────────────────────────────────────────
alter publication supabase_realtime add table public.torneios;
alter publication supabase_realtime add table public.inscricoes;
alter publication supabase_realtime add table public.partidas;
