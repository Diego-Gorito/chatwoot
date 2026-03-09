-- Debug Kanban Automation
-- Execute estas queries no PostgreSQL do Chatwoot

-- 1. Verificar boards existentes e suas configurações
SELECT
    kb.id,
    kb.name,
    kb.settings,
    kb.steps_order,
    a.name as account_name,
    COUNT(DISTINCT kbi.inbox_id) as inbox_count,
    COUNT(DISTINCT kbs.id) as step_count
FROM kanban_boards kb
JOIN accounts a ON kb.account_id = a.id
LEFT JOIN kanban_board_inboxes kbi ON kb.id = kbi.board_id
LEFT JOIN kanban_board_steps kbs ON kb.id = kbs.board_id
GROUP BY kb.id, kb.name, kb.settings, kb.steps_order, a.name
ORDER BY kb.created_at DESC;

-- 2. Verificar inboxes associadas ao board
SELECT
    kb.id as board_id,
    kb.name as board_name,
    i.id as inbox_id,
    i.name as inbox_name,
    i.channel_type
FROM kanban_boards kb
JOIN kanban_board_inboxes kbi ON kb.id = kbi.board_id
JOIN inboxes i ON kbi.inbox_id = i.id
ORDER BY kb.id, i.name;

-- 3. Verificar steps do board
SELECT
    kb.id as board_id,
    kb.name as board_name,
    kbs.id as step_id,
    kbs.name as step_name,
    kbs.cancelled,
    kbs.tasks_count
FROM kanban_boards kb
JOIN kanban_board_steps kbs ON kb.id = kbs.board_id
ORDER BY kb.id, kbs.created_at;

-- 4. Verificar se a feature kanban está habilitada para a conta
SELECT
    a.id,
    a.name,
    a.feature_flags,
    -- Verifica se o bit da feature kanban está ativo
    CASE
        WHEN a.feature_flags IS NOT NULL THEN 'Check feature_flags column'
        ELSE 'NULL - features may be disabled'
    END as kanban_status
FROM accounts a
ORDER BY a.created_at DESC
LIMIT 10;

-- 5. Verificar últimas conversas criadas
SELECT
    c.id,
    c.display_id,
    c.status,
    c.created_at,
    i.name as inbox_name,
    c.kanban_task_id,
    CASE
        WHEN c.kanban_task_id IS NULL THEN 'No task created'
        ELSE 'Task exists'
    END as task_status
FROM conversations c
JOIN inboxes i ON c.inbox_id = i.id
WHERE c.created_at > NOW() - INTERVAL '24 hours'
ORDER BY c.created_at DESC
LIMIT 20;

-- 6. Verificar últimas tasks criadas
SELECT
    kt.id,
    kt.title,
    kt.created_at,
    kb.name as board_name,
    kbs.name as step_name,
    kt.conversation_ids
FROM kanban_tasks kt
JOIN kanban_boards kb ON kt.board_id = kb.id
JOIN kanban_board_steps kbs ON kt.board_step_id = kbs.id
ORDER BY kt.created_at DESC
LIMIT 20;

-- 7. Verificar se há jobs pendentes ou com erro (se você usa Sidekiq)
-- Esta query só funciona se você armazena jobs no PostgreSQL
SELECT
    COUNT(*) as job_count,
    queue,
    error_class
FROM sidekiq_jobs
WHERE created_at > NOW() - INTERVAL '1 hour'
GROUP BY queue, error_class;