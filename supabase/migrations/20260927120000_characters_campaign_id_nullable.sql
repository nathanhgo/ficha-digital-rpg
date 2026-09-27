-- Fix: criar personagem sem campanha ("avulso") falhava no cliente.
--
-- Causa do bug era no cliente (String `'avulso'`/`''` enviada para a coluna
-- `uuid campaign_id`), mas este script garante, de forma idempotente e não
-- destrutiva, que a coluna permita NULL em bancos já provisionados que tenham
-- recebido um NOT NULL fora do supabase/supabase_schema.sql.
--
-- O schema de referência do repositório já declara a coluna como anulável:
--   campaign_id uuid references public.campaigns(id) on delete set null
-- por isso `drop not null` não altera dados e é no-op quando já está anulável.

alter table if exists public.characters
    alter column campaign_id drop not null;
