-- Verificar se as tabelas existem em QUALQUER schema
SELECT
    schemaname,
    tablename
FROM pg_tables
WHERE tablename LIKE '%kanban%'
ORDER BY schemaname, tablename;

-- Verificar o schema atual
SHOW search_path;

-- Verificar todas as tabelas no banco
SELECT
    schemaname,
    COUNT(*) as table_count
FROM pg_tables
GROUP BY schemaname;

-- Verificar especificamente no schema public
SELECT
    tablename
FROM pg_tables
WHERE schemaname = 'public'
    AND tablename LIKE '%kanban%';

-- Verificar se existe em outro schema (como 'enterprise' ou 'fazer_ai')
SELECT
    n.nspname as schema_name,
    c.relname as table_name
FROM pg_catalog.pg_class c
JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE c.relname LIKE '%kanban%'
    AND c.relkind = 'r';

-- Verificar a tabela de migrations para ver se foram executadas
SELECT version, migrated_at
FROM schema_migrations
WHERE version LIKE '%kanban%'
   OR version IN (
       '20251117080000',
       '20251117090000',
       '20260103192932',
       '20260103224422',
       '20260110194043',
       '20260116203007',
       '20260121203242',
       '20260122230737',
       '20260306210544',
       '20260309000001'
   )
ORDER BY version;

-- Listar TODAS as migrations para verificar
SELECT COUNT(*) as total_migrations,
       MAX(version) as latest_migration
FROM schema_migrations;

-- Verificar se as tabelas foram criadas com prefixo ou em outro formato
SELECT
    tablename
FROM pg_tables
WHERE schemaname = 'public'
    AND (
        tablename LIKE '%board%'
        OR tablename LIKE '%task%'
        OR tablename LIKE '%step%'
    )
ORDER BY tablename;