-- Rode no Supabase: SQL Editor > New query > Run
create table if not exists pessoas (
  id uuid primary key default gen_random_uuid(),
  matricula text unique not null,
  nome text not null,
  local_trabalho text,
  foto_path text,
  foto_em timestamptz,
  criado_em timestamptz default now()
);

alter table pessoas enable row level security;

drop policy if exists "logado total" on pessoas;
create policy "logado total" on pessoas
  for all to authenticated using (true) with check (true);

insert into storage.buckets (id, name, public)
values ('fotos', 'fotos', false)
on conflict (id) do nothing;

drop policy if exists "logado fotos" on storage.objects;
create policy "logado fotos" on storage.objects
  for all to authenticated
  using (bucket_id = 'fotos') with check (bucket_id = 'fotos');
