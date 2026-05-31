-- ==========================================
-- SCRIPT DE CRIAÇÃO DO BANCO - DESPERTAR DO CAOS
-- ==========================================

-- Habilitar extensões necessárias
create extension if not exists "uuid-ossp";

-- 1. TABELA DE PERFIS DE USUÁRIOS
create table public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    username text unique not null,
    role text not null check (role in ('master', 'player')) default 'player',
    created_at timestamptz default now()
);

-- Ativar RLS para perfis
alter table public.profiles disable row level security;

-- 2. TABELA DE CAMPANHAS
create table public.campaigns (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    description text,
    map_url text,
    master_id uuid not null references public.profiles(id) on delete cascade,
    created_at timestamptz default now()
);

alter table public.campaigns disable row level security;

-- 3. TABELA DE JOGADORES DA CAMPANHA (JUNÇÃO MANY-TO-MANY)
create table public.campaign_players (
    campaign_id uuid references public.campaigns(id) on delete cascade,
    player_id uuid references public.profiles(id) on delete cascade,
    joined_at timestamptz default now(),
    primary key (campaign_id, player_id)
);

alter table public.campaign_players disable row level security;

-- 4. TABELA DE FICHAS DE PERSONAGENS
create table public.characters (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references public.profiles(id) on delete cascade,
    campaign_id uuid references public.campaigns(id) on delete set null,
    name text not null,
    level int not null default 0,
    xp int not null default 0,
    dv_value int not null default 8,
    race text,
    char_class text,
    subclass text,
    profession text,
    current_fv int not null default 10,
    max_fv int not null default 10,
    current_vigor int not null default 10,
    max_vigor int not null default 10,
    sanidade int not null default 100,
    conciencia int not null default 100,
    current_pm int not null default 100,
    max_pm int not null default 100,
    efeitos jsonb not null default '[]'::jsonb,
    fome int not null default 50,
    sede int not null default 50,
    sangue int not null default 100,
    caos int not null default 0,
    exposicao_rad int not null default 0,
    e_essencia int not null default 0,
    vapor int not null default 0,
    oleo int not null default 0,
    c_corpo text,
    c_clima text,
    avatar_url text,
    attributes jsonb not null default '{"CON": 10, "FOR": 10, "DES": 10, "AGI": 10, "CAR": 10, "VON": 10, "INT": 10, "PER": 10}'::jsonb,
    skills jsonb not null default '{}'::jsonb,
    life_details jsonb not null default '{"ideals": "", "weaknesses": "", "qualities": "", "bonds": "", "personality_traits": ""}'::jsonb,
    is_dead boolean not null default false,
    diary text default '',
    created_at timestamptz default now()
);

alter table public.characters disable row level security;

-- 5. TABELA DE SESSÕES
create table public.sessions (
    id uuid primary key default gen_random_uuid(),
    campaign_id uuid not null references public.campaigns(id) on delete cascade,
    title text not null,
    notes text default '',
    start_time timestamptz,
    end_time timestamptz,
    status text not null check (status in ('scheduled', 'active', 'finished')) default 'scheduled',
    created_at timestamptz default now()
);

alter table public.sessions disable row level security;

-- 6. TABELA DE PARTICIPANTES DA SESSÃO (PRESENÇA REALTIME)
create table public.session_participants (
    session_id uuid references public.sessions(id) on delete cascade,
    character_id uuid references public.characters(id) on delete cascade,
    joined_at timestamptz default now(),
    primary key (session_id, character_id)
);

alter table public.session_participants disable row level security;

-- 7. TABELA DE ITENS (TEMPLATES E ITENS GERAIS)
create table public.items (
    id uuid primary key default gen_random_uuid(),
    campaign_id uuid references public.campaigns(id) on delete cascade,
    name text not null,
    description text,
    weight numeric(10, 2) not null default 0.00,
    image_url text,
    is_template boolean not null default false,
    created_at timestamptz default now()
);

alter table public.items disable row level security;

-- 8. TABELA DE INVENTÁRIO DO PERSONAGEM (JUNÇÃO ITEM -> PERSONAGEM)
create table public.character_inventory (
    id uuid primary key default gen_random_uuid(),
    character_id uuid not null references public.characters(id) on delete cascade,
    item_id uuid not null references public.items(id) on delete cascade,
    quantity int not null default 1,
    accepted boolean not null default false,
    created_at timestamptz default now()
);

alter table public.character_inventory disable row level security;

-- 9. TABELA DE DOCUMENTOS PÚBLICOS DO MUNDO
create table public.public_documents (
    id uuid primary key default gen_random_uuid(),
    campaign_id uuid not null references public.campaigns(id) on delete cascade,
    author_id uuid not null references public.profiles(id) on delete cascade,
    title text not null,
    content text,
    category text not null check (category in ('jornal', 'lore', 'mapa', 'pesquisa', 'outros')),
    image_url text,
    status text not null check (status in ('pending', 'approved', 'rejected')) default 'pending',
    rejection_reason text,
    created_at timestamptz default now()
);

alter table public.public_documents disable row level security;


-- ==========================================
-- TRIGGERS E FUNÇÕES AUXILIARES
-- ==========================================

-- Trigger para criar perfil automaticamente na tabela 'profiles' após o cadastro no Supabase Auth
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, role)
  values (
    new.id, 
    coalesce(new.raw_user_meta_data->>'username', 'Jogador_' || substring(new.id::text from 1 for 6)), 
    coalesce(new.raw_user_meta_data->>'role', 'player')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- ==========================================
-- POLÍTICAS DE ROW LEVEL SECURITY (RLS)
-- ==========================================

-- 1. POLÍTICAS: PROFILES
create policy "Qualquer usuário logado pode ler perfis" 
on public.profiles for select using (auth.uid() is not null);

create policy "Usuários podem editar seu próprio perfil" 
on public.profiles for update using (auth.uid() = id);

-- 2. POLÍTICAS: CAMPAIGNS
create policy "Leitura de campanhas para usuários autenticados" 
on public.campaigns for select using (auth.uid() is not null);

create policy "Apenas o Mestre pode inserir campanhas" 
on public.campaigns for insert with check (
    exists (
        select 1 from public.profiles 
        where profiles.id = auth.uid() and profiles.role = 'master'
    )
);

create policy "Apenas o Mestre proprietário pode alterar campanhas" 
on public.campaigns for update using (auth.uid() = master_id);

create policy "Apenas o Mestre proprietário pode deletar campanhas" 
on public.campaigns for delete using (auth.uid() = master_id);

-- 3. POLÍTICAS: CAMPAIGN_PLAYERS
create policy "Leitura de participantes para usuários autenticados" 
on public.campaign_players for select using (auth.uid() is not null);

create policy "Jogadores podem se inscrever ou o Mestre pode adicionar" 
on public.campaign_players for insert with check (
    auth.uid() = player_id or
    exists (
        select 1 from public.campaigns 
        where campaigns.id = campaign_id and campaigns.master_id = auth.uid()
    )
);

create policy "Mestre ou jogador podem remover presença da campanha" 
on public.campaign_players for delete using (
    auth.uid() = player_id or
    exists (
        select 1 from public.campaigns 
        where campaigns.id = campaign_id and campaigns.master_id = auth.uid()
    )
);

-- 4. POLÍTICAS: CHARACTERS (FICHAS)
create policy "Visualização de Fichas (Dono, Mestre ou Mortos na mesa)" 
on public.characters for select using (
    auth.uid() = owner_id or
    exists (
        select 1 from public.campaigns 
        where campaigns.id = campaign_id and campaigns.master_id = auth.uid()
    ) or
    (is_dead = true and exists (
        select 1 from public.campaign_players 
        where campaign_players.campaign_id = campaign_id and campaign_players.player_id = auth.uid()
    ))
);

create policy "Qualquer jogador pode criar fichas" 
on public.characters for insert with check (auth.uid() = owner_id);

create policy "Jogadores podem editar suas fichas vivas e Mestres editam a qualquer momento" 
on public.characters for update using (
    (auth.uid() = owner_id and is_dead = false) or
    exists (
        select 1 from public.campaigns 
        where campaigns.id = campaign_id and campaigns.master_id = auth.uid()
    )
);

-- 5. POLÍTICAS: SESSIONS
create policy "Membros da campanha podem visualizar sessões" 
on public.sessions for select using (
    exists (
        select 1 from public.campaigns 
        where campaigns.id = campaign_id and (
            campaigns.master_id = auth.uid() or 
            exists (
                select 1 from public.campaign_players 
                where campaign_players.campaign_id = campaigns.id and campaign_players.player_id = auth.uid()
            )
        )
    )
);

create policy "Apenas o Mestre pode criar sessões" 
on public.sessions for insert with check (
    exists (
        select 1 from public.campaigns 
        where campaigns.id = campaign_id and campaigns.master_id = auth.uid()
    )
);

create policy "Apenas o Mestre pode alterar sessões" 
on public.sessions for update using (
    exists (
        select 1 from public.campaigns 
        where campaigns.id = campaign_id and campaigns.master_id = auth.uid()
    )
);

-- 6. POLÍTICAS: SESSION_PARTICIPANTS
create policy "Membros da mesa podem visualizar participantes da sessão" 
on public.session_participants for select using (
    exists (
        select 1 from public.sessions 
        join public.campaigns on campaigns.id = sessions.campaign_id
        where sessions.id = session_id and (
            campaigns.master_id = auth.uid() or 
            exists (
                select 1 from public.campaign_players 
                where campaign_players.campaign_id = campaigns.id and campaign_players.player_id = auth.uid()
            )
        )
    )
);

create policy "Jogadores podem entrar em sessões ativas" 
on public.session_participants for insert with check (
    exists (
        select 1 from public.characters 
        where characters.id = character_id and characters.owner_id = auth.uid()
    ) and exists (
        select 1 from public.sessions 
        where sessions.id = session_id and sessions.status = 'active'
    )
);

create policy "Mestre ou o próprio jogador podem remover presença da sessão" 
on public.session_participants for delete using (
    exists (
        select 1 from public.characters 
        where characters.id = character_id and characters.owner_id = auth.uid()
    ) or exists (
        select 1 from public.sessions 
        join public.campaigns on campaigns.id = sessions.campaign_id
        where sessions.id = session_id and campaigns.master_id = auth.uid()
    )
);

-- 7. POLÍTICAS: ITEMS
create policy "Qualquer usuário logado pode gerenciar itens" 
on public.items for all using (
    auth.uid() is not null
);

-- 8. POLÍTICAS: CHARACTER_INVENTORY
create policy "Visualização de Inventário" 
on public.character_inventory for select using (
    exists (
        select 1 from public.characters 
        where characters.id = character_id and (
            characters.owner_id = auth.uid() or 
            exists (
                select 1 from public.campaigns 
                where campaigns.id = characters.campaign_id and campaigns.master_id = auth.uid()
            )
        )
    )
);

create policy "Mestre ou o próprio jogador podem adicionar itens ao inventário" 
on public.character_inventory for insert with check (
    exists (
        select 1 from public.characters 
        where characters.id = character_id and (
            characters.owner_id = auth.uid() or 
            exists (
                select 1 from public.campaigns 
                where campaigns.id = characters.campaign_id and campaigns.master_id = auth.uid()
            )
        )
    )
);

create policy "Mestre ou jogador podem atualizar e deletar do inventário" 
on public.character_inventory for all using (
    exists (
        select 1 from public.characters 
        where characters.id = character_id and (
            characters.owner_id = auth.uid() or 
            exists (
                select 1 from public.campaigns 
                where campaigns.id = characters.campaign_id and campaigns.master_id = auth.uid()
            )
        )
    )
);

-- 9. POLÍTICAS: PUBLIC_DOCUMENTS
create policy "Leitura de documentos (Aprovados ou Pendentes/Rejeitados do autor/mestre)" 
on public.public_documents for select using (
    status = 'approved' or
    author_id = auth.uid() or
    exists (
        select 1 from public.campaigns 
        where campaigns.id = campaign_id and campaigns.master_id = auth.uid()
    )
);

create policy "Qualquer membro da campanha pode submeter documentos" 
on public.public_documents for insert with check (
    author_id = auth.uid() and (
        exists (
            select 1 from public.campaign_players 
            where campaign_players.campaign_id = campaign_id and campaign_players.player_id = auth.uid()
        ) or exists (
            select 1 from public.campaigns 
            where campaigns.id = campaign_id and campaigns.master_id = auth.uid()
        )
    )
);

create policy "Autores editam se pendente/rejeitado, Mestre altera status" 
on public.public_documents for update using (
    (author_id = auth.uid() and status in ('pending', 'rejected')) or
    exists (
        select 1 from public.campaigns 
        where campaigns.id = campaign_id and campaigns.master_id = auth.uid()
    )
);

-- ==========================================
-- NOVAS TABELAS DO SISTEMA
-- ==========================================

-- Tabela de Notificações
create table public.notifications (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    title text not null,
    message text not null,
    is_read boolean not null default false,
    created_at timestamptz default now()
);

alter table public.notifications disable row level security;

-- Tabela de Documentos Pessoais do Personagem
create table public.character_documents (
    id uuid primary key default gen_random_uuid(),
    character_id uuid not null references public.characters(id) on delete cascade,
    title text not null,
    content text,
    file_url text,
    created_at timestamptz default now()
);

alter table public.character_documents disable row level security;

-- ==========================================
-- ALTERAÇÕES INCREMENTAIS (SPRINT 2)
-- ==========================================

-- Adiciona tipo e metadados às notificações para suportar convites de sessão
alter table public.notifications
    add column if not exists type text not null default 'general',
    add column if not exists metadata jsonb not null default '{}';

-- Adiciona resumo público das sessões para os jogadores
alter table public.sessions
    add column if not exists player_summary text not null default '';


-- ==========================================
-- INICIALIZAÇÃO DO STORAGE BUCKET E POLÍTICAS
-- ==========================================

-- Criar bucket de armazenamento 'rpg-files' se não existir
insert into storage.buckets (id, name, public)
values ('rpg-files', 'rpg-files', true)
on conflict (id) do nothing;

-- Remover políticas existentes para evitar erros de duplicidade ao re-executar
drop policy if exists "Leitura pública de objetos em rpg-files" on storage.objects;
drop policy if exists "Inserção de objetos em rpg-files para autenticados" on storage.objects;
drop policy if exists "Atualização de objetos em rpg-files para autenticados" on storage.objects;
drop policy if exists "Exclusão de objetos em rpg-files para autenticados" on storage.objects;

-- Criar políticas de RLS para o storage
create policy "Leitura pública de objetos em rpg-files"
on storage.objects for select
using (bucket_id = 'rpg-files');

create policy "Inserção de objetos em rpg-files para autenticados"
on storage.objects for insert
with check (bucket_id = 'rpg-files' and auth.role() = 'authenticated');

create policy "Atualização de objetos em rpg-files para autenticados"
on storage.objects for update
using (bucket_id = 'rpg-files' and auth.role() = 'authenticated');

create policy "Exclusão de objetos em rpg-files para autenticados"
on storage.objects for delete
using (bucket_id = 'rpg-files' and auth.role() = 'authenticated');

-- ==========================================
-- SPRINT 3: SISTEMA E LORE
-- ==========================================

create table public.system_posts (
    id uuid primary key default gen_random_uuid(),
    author_id uuid not null references public.profiles(id) on delete cascade,
    title text not null,
    content text not null,
    created_at timestamptz default now()
);

alter table public.system_posts disable row level security;

-- ==========================================
-- SPRINT 4: INVENTÁRIO AVANÇADO
-- ==========================================

alter table public.items add column if not exists category text not null default 'item';
alter table public.character_inventory add column if not exists durability int not null default 20;


