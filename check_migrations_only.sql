-- Verificar apenas as migrations do Kanban
-- Essas versões deveriam estar na tabela schema_migrations se tivessem sido executadas

SELECT
    '20251117080000' as expected_version,
    EXISTS(SELECT 1 FROM schema_migrations WHERE version = '20251117080000') as exists,
    'shift_feature_flags_for_kanban' as description
UNION ALL
SELECT
    '20251117090000',
    EXISTS(SELECT 1 FROM schema_migrations WHERE version = '20251117090000'),
    'create_kanban_core_tables'
UNION ALL
SELECT
    '20260103192932',
    EXISTS(SELECT 1 FROM schema_migrations WHERE version = '20260103192932'),
    'rename_end_date_to_due_date_in_kanban_tasks'
UNION ALL
SELECT
    '20260103224422',
    EXISTS(SELECT 1 FROM schema_migrations WHERE version = '20260103224422'),
    'add_cached_label_list_to_kanban_tasks'
ORDER BY expected_version;

-- Verificar a última migration executada
SELECT
    MAX(version) as last_migration_version,
    COUNT(*) as total_migrations
FROM schema_migrations;

-- Verificar se há alguma migration depois de novembro de 2025
SELECT version
FROM schema_migrations
WHERE version > '20251100000000'
ORDER BY version
LIMIT 10;