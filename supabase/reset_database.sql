-- ==========================================
-- SCRIPT DE RESET COMPLETO DO BANCO
-- Despertar do Caos RPG
--
-- INSTRUÇÕES:
-- 1. Cole e execute este script PRIMEIRO no SQL Editor do Supabase
-- 2. Após o sucesso, cole e execute o conteúdo de supabase_schema.sql
-- ==========================================

-- Remover triggers antes das tabelas
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

-- Remover tabelas na ordem inversa (filhos antes dos pais)
drop table if exists public.character_documents cascade;
drop table if exists public.notifications cascade;
drop table if exists public.public_documents cascade;
drop table if exists public.character_inventory cascade;
drop table if exists public.items cascade;
drop table if exists public.session_participants cascade;
drop table if exists public.sessions cascade;
drop table if exists public.characters cascade;
drop table if exists public.campaign_players cascade;
drop table if exists public.campaigns cascade;
drop table if exists public.profiles cascade;

-- Remover políticas de RLS órfãs (segurança extra)
-- (As políticas são removidas automaticamente com as tabelas via CASCADE)

-- Confirmação
select 'Reset concluído! Agora execute o supabase_schema.sql' as status;
