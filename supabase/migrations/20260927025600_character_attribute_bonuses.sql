-- ==========================================
-- MIGRAÇÃO: SISTEMA DE BÔNUS DE ATRIBUTOS
-- DESPERTAR DO CAOS - ficha-digital-rpg
-- ==========================================
--
-- COMO EXECUTAR (manual):
-- 1. Abra o painel do seu projeto no Supabase
-- 2. Vá em SQL Editor -> New query
-- 3. Cole e execute este arquivo inteiro
--
-- O QUE ESTA MIGRAÇÃO FAZ:
-- Cria a tabela `character_attribute_bonuses`, que guarda os bônus externos
-- (raça, equipamento, etc.) somados ao valor base dos atributos do personagem.
-- O valor final exibido na ficha é: characters.attributes + soma dos bônus.
--
-- A migração pode ser executada mais de uma vez sem erro (if not exists /
-- drop policy if exists).
-- ==========================================

-- 1. TABELA DE BÔNUS DE ATRIBUTOS DO PERSONAGEM
create table if not exists public.character_attribute_bonuses (
    id uuid primary key default gen_random_uuid(),
    character_id uuid not null references public.characters(id) on delete cascade,
    source text not null,
    attribute text not null,
    amount integer not null,
    created_at timestamptz default now()
);

-- 2. ÍNDICES NECESSÁRIOS
-- Busca principal do app: todos os bônus de um personagem, em ordem de criação.
create index if not exists character_attribute_bonuses_character_id_idx
    on public.character_attribute_bonuses (character_id, created_at);

-- 3. ATIVAR RLS
-- Observação: as demais tabelas do schema usam `disable row level security`,
-- mas aqui o RLS fica ATIVO para que as políticas abaixo realmente valham.
alter table public.character_attribute_bonuses enable row level security;

-- 4. POLÍTICAS DE ROW LEVEL SECURITY
-- Regra geral: o dono do personagem OU o mestre da campanha do personagem
-- podem ler/gerenciar os bônus. Mesmo estilo de public.character_inventory.

drop policy if exists "Visualização de Bônus de Atributo do Personagem" on public.character_attribute_bonuses;
drop policy if exists "Dono do personagem ou Mestre podem inserir bônus de atributo" on public.character_attribute_bonuses;
drop policy if exists "Dono do personagem ou Mestre podem alterar bônus de atributo" on public.character_attribute_bonuses;
drop policy if exists "Dono do personagem ou Mestre podem remover bônus de atributo" on public.character_attribute_bonuses;

create policy "Visualização de Bônus de Atributo do Personagem"
on public.character_attribute_bonuses for select using (
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

create policy "Dono do personagem ou Mestre podem inserir bônus de atributo"
on public.character_attribute_bonuses for insert with check (
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

create policy "Dono do personagem ou Mestre podem alterar bônus de atributo"
on public.character_attribute_bonuses for update using (
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

create policy "Dono do personagem ou Mestre podem remover bônus de atributo"
on public.character_attribute_bonuses for delete using (
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

-- 5. CONFIRMAÇÃO
select 'Migração de bônus de atributos concluída!' as status;
