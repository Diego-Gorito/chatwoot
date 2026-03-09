# 🚨 IMPORTANTE: Executar Migrations do Kanban

As tabelas do Kanban não existem no banco de dados de produção!

## Comandos para executar no servidor:

### 1. Conecte via SSH ao servidor
```bash
ssh seu_usuario@chatwoot.zerohumnatal.com
```

### 2. Navegue até a pasta do Chatwoot
```bash
cd /caminho/para/chatwoot
```

### 3. Execute as migrations
```bash
# Fazer backup do banco antes (IMPORTANTE!)
pg_dump chatwoot_production > backup_antes_kanban.sql

# Executar as migrations
RAILS_ENV=production bundle exec rails db:migrate

# Se estiver usando Docker:
docker exec -it chatwoot_rails bundle exec rails db:migrate RAILS_ENV=production
```

### 4. Reinicie o servidor
```bash
# Se usar systemctl
sudo systemctl restart chatwoot

# Se usar docker
docker-compose restart

# Se usar outro método
# Reinicie conforme seu setup
```

## Migrations que serão executadas:

1. `20251117080000_shift_feature_flags_for_kanban.rb` - Prepara feature flags
2. `20251117090000_create_kanban_core_tables.rb` - Cria todas as tabelas principais:
   - kanban_boards
   - kanban_board_steps
   - kanban_tasks
   - kanban_task_contacts
   - kanban_task_agents
   - kanban_board_agents
   - kanban_board_inboxes
   - kanban_audit_events
   - kanban_account_user_preferences

3. Outras migrations complementares para índices e ajustes

## Verificação após executar:

```sql
-- Verificar se as tabelas foram criadas
\dt kanban_*

-- Ou
SELECT tablename FROM pg_tables
WHERE tablename LIKE 'kanban_%'
ORDER BY tablename;
```

## ⚠️ ATENÇÃO

- **FAÇA BACKUP ANTES** de executar as migrations
- As migrations são seguras, mas sempre é bom ter backup
- Após executar, o Kanban estará 100% funcional
- Todas as automações funcionarão corretamente

## Por que isso aconteceu?

Provavelmente o código foi deployado mas as migrations não foram executadas no deploy.
Isso é comum quando:
- O processo de deploy não inclui `rails db:migrate`
- As migrations foram adicionadas depois do deploy inicial
- Houve algum erro no processo de deploy

## Após executar as migrations:

1. ✅ As tabelas do Kanban existirão
2. ✅ Você poderá criar boards/funnels
3. ✅ As automações funcionarão
4. ✅ Novas conversas criarão tasks automaticamente