-- Debug Kanban - Versão Simplificada
-- Execute no PostgreSQL e envie os resultados

-- 1. Verificar o board "Sales Pipeline" e suas configurações
SELECT
    id,
    name,
    settings,
    steps_order,
    created_at,
    updated_at
FROM kanban_boards
WHERE name LIKE '%Sales%' OR name LIKE '%Pipeline%'
ORDER BY created_at DESC;

-- 2. Para o board encontrado acima, use o ID aqui (substitua X pelo ID do board)
-- Exemplo: WHERE kb.id = 1
SELECT
    kb.name as board_name,
    kb.settings -> 'auto_create_task_for_conversation' as auto_create_enabled,
    kb.settings -> 'auto_assign_task_to_agent' as auto_assign_enabled,
    kb.settings -> 'sync_task_and_conversation_agents' as sync_agents,
    kb.settings -> 'auto_resolve_conversation_on_task_end' as auto_resolve,
    kb.settings -> 'auto_complete_task_on_conversation_resolve' as auto_complete,
    COUNT(DISTINCT kbi.inbox_id) as total_inboxes,
    COUNT(DISTINCT kbs.id) as total_steps
FROM kanban_boards kb
LEFT JOIN kanban_board_inboxes kbi ON kb.id = kbi.board_id
LEFT JOIN kanban_board_steps kbs ON kb.id = kbs.board_id
WHERE kb.name LIKE '%Sales%' OR kb.name LIKE '%Pipeline%'
GROUP BY kb.id, kb.name, kb.settings;

-- 3. Listar inboxes associadas ao board
SELECT
    kb.name as board_name,
    i.id as inbox_id,
    i.name as inbox_name
FROM kanban_boards kb
JOIN kanban_board_inboxes kbi ON kb.id = kbi.board_id
JOIN inboxes i ON kbi.inbox_id = i.id
WHERE kb.name LIKE '%Sales%' OR kb.name LIKE '%Pipeline%';

-- 4. Listar steps do board em ordem
SELECT
    kb.name as board_name,
    kbs.id as step_id,
    kbs.name as step_name,
    kbs.cancelled,
    ARRAY_POSITION(kb.steps_order, kbs.id) as position_in_order
FROM kanban_boards kb
JOIN kanban_board_steps kbs ON kb.id = kbs.board_id
WHERE kb.name LIKE '%Sales%' OR kb.name LIKE '%Pipeline%'
ORDER BY ARRAY_POSITION(kb.steps_order, kbs.id);

-- 5. Verificar últimas 10 conversas e se geraram tasks
SELECT
    c.id,
    c.display_id,
    c.created_at,
    i.name as inbox_name,
    c.kanban_task_id,
    kt.title as task_title,
    kbs.name as task_step
FROM conversations c
JOIN inboxes i ON c.inbox_id = i.id
LEFT JOIN kanban_tasks kt ON c.kanban_task_id = kt.id
LEFT JOIN kanban_board_steps kbs ON kt.board_step_id = kbs.id
WHERE c.created_at > NOW() - INTERVAL '48 hours'
ORDER BY c.created_at DESC
LIMIT 10;

-- 6. Verificar se há algum board com auto_create habilitado
SELECT
    name,
    settings,
    CASE
        WHEN settings::text LIKE '%auto_create_task_for_conversation%true%' THEN 'YES'
        ELSE 'NO'
    END as auto_create_enabled
FROM kanban_boards;

-- 7. Contar conversas vs tasks criadas hoje
SELECT
    COUNT(DISTINCT c.id) as conversations_today,
    COUNT(DISTINCT kt.id) as tasks_today
FROM conversations c
LEFT JOIN kanban_tasks kt ON kt.created_at::date = CURRENT_DATE
WHERE c.created_at::date = CURRENT_DATE;