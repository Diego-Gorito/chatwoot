# 🤖 Guia de Automação Kanban - Atualizações do Chatwoot

## 📋 Resumo Executivo

Criei um sistema **100% automatizado** para integrar o Kanban sempre que uma nova versão do Chatwoot for lançada. Você não precisa fazer NADA manualmente - o sistema cuida de tudo!

## ✨ Como Funciona

### 🔄 Automático (Recomendado)

**Todos os dias às 2 AM UTC**, um robô:

1. ✅ Verifica se há nova versão do Chatwoot
2. ✅ Se encontrar, faz merge automático
3. ✅ Aplica os patches do Kanban (2 arquivos)
4. ✅ Roda os testes
5. ✅ Cria um Pull Request para você revisar
6. ✅ Se tudo OK, você só aprova e faz merge!

**Você só precisa:**
- Esperar o PR aparecer no GitHub
- Revisar as mudanças
- Aprovar e fazer merge
- Reiniciar o servidor

### 🎮 Manual (Se Quiser Atualizar Agora)

```bash
# Atualizar para a versão mais recente
.kanban-patches/scripts/merge-upstream.sh develop

# Ou para uma versão específica
.kanban-patches/scripts/merge-upstream.sh v3.2.0
```

## 📁 O Que Foi Criado

### 1. Sistema de Patches (`.kanban-patches/`)

```
.kanban-patches/
├── README.md                      # Visão geral do sistema
├── patches/                       # Patches dos 2 arquivos core
│   ├── 001-redis-keys.patch      # Adiciona constante Redis
│   └── 002-event-types.patch     # Adiciona eventos Kanban
├── scripts/                       # Scripts de automação
│   ├── apply-patches.sh          # Aplica os patches
│   └── merge-upstream.sh         # Faz merge + patches
└── docs/                          # Documentação completa
    ├── USAGE.md                   # Como usar (em inglês)
    ├── CHANGES.md                 # Lista todas mudanças
    └── MIGRATION.md               # Instalação do zero
```

### 2. GitHub Actions (`.github/workflows/`)

- **sync-upstream-chatwoot.yml** - Workflow que roda diariamente
- Checa novas versões automaticamente
- Cria PRs com tudo pronto
- Roda testes antes de criar o PR

## 🎯 Patches Aplicados

Apenas **2 arquivos** do Chatwoot core são modificados:

### Patch 1: Redis Keys (`lib/redis/redis_keys.rb`)
```ruby
## Kanban Keys
KANBAN_BOARD_ROUND_ROBIN_AGENTS = 'KANBAN_BOARD_ROUND_ROBIN_AGENTS:%<board_id>d'.freeze
```
**Por quê:** Para round-robin de agentes nos boards

### Patch 2: Event Types (`lib/events/types.rb`)
```ruby
# kanban events
KANBAN_BOARD_CREATED = 'kanban.board.created'
KANBAN_BOARD_UPDATED = 'kanban.board.updated'
KANBAN_BOARD_DELETED = 'kanban.board.deleted'
KANBAN_TASK_CREATED = 'kanban.task.created'
KANBAN_TASK_UPDATED = 'kanban.task.updated'
KANBAN_TASK_DELETED = 'kanban.task.deleted'
KANBAN_TASK_MOVED = 'kanban.task.moved'
```
**Por quê:** Para eventos ActionCable e webhooks

**TODO o resto do código Kanban fica isolado na pasta `fazer_ai/`** - não toca em nada do Chatwoot core!

## 🚀 Primeiro Uso

### Ativar o GitHub Actions

1. Vá no seu repositório no GitHub
2. Clique em "Actions"
3. Habilite workflows se não estiver habilitado
4. O workflow "Sync Upstream Chatwoot" começará a rodar diariamente

### Testar Agora (Opcional)

Se quiser testar sem esperar:

1. No GitHub, vá em Actions
2. Selecione "Sync Upstream Chatwoot"
3. Clique "Run workflow"
4. Escolha a versão (ex: `develop`)
5. Clique "Run workflow"
6. Aguarde alguns minutos
7. Um PR será criado automaticamente!

## 📊 O Que Acontece no PR Automático

O PR incluirá:

- ✅ Merge das mudanças upstream
- ✅ Patches aplicados automaticamente
- ✅ Resultados dos testes
- ✅ Checklist de revisão
- ✅ Instruções de deployment
- ✅ Se houver conflitos, vira Draft PR para você resolver

## 🔧 Manutenção Zero

O sistema é auto-suficiente:

- **Diariamente:** Checa por updates
- **Automaticamente:** Cria PRs quando encontra
- **Testes:** Roda antes de criar PR
- **Seguro:** Cria draft se algo falhar

Você só age quando:
1. Aparecer um PR (revisar e aprovar)
2. Algo falhar (resolver conflitos manualmente)

## 📖 Documentação Completa

Toda documentação está em `.kanban-patches/docs/`:

| Arquivo | Conteúdo |
|---------|----------|
| **USAGE.md** | Como usar no dia-a-dia |
| **CHANGES.md** | Lista completa de mudanças |
| **MIGRATION.md** | Como instalar do zero |

## 🎓 Exemplos de Uso

### Atualizar Manualmente

```bash
# Atualizar para develop
.kanban-patches/scripts/merge-upstream.sh develop

# Atualizar para v3.2.0
.kanban-patches/scripts/merge-upstream.sh v3.2.0
```

### Aplicar Patches Apenas

```bash
# Se por algum motivo os patches não foram aplicados
.kanban-patches/scripts/apply-patches.sh
```

### Ver O Que Os Patches Fazem

```bash
# Ver patch 1 (Redis)
cat .kanban-patches/patches/001-redis-keys.patch

# Ver patch 2 (Events)
cat .kanban-patches/patches/002-event-types.patch
```

## 🛡️ Segurança

O sistema é seguro:

- ✅ Nunca faz push direto para main
- ✅ Sempre cria branch separada
- ✅ Sempre cria PR para revisão
- ✅ Roda testes antes
- ✅ Detecta conflitos
- ✅ Cria draft se algo falhar

## 🆘 Troubleshooting

### PR com Conflitos

Se o PR mostrar conflitos:

```bash
# 1. Puxar o branch
git fetch origin
git checkout merge/upstream-vX.X.X-TIMESTAMP

# 2. Resolver conflitos manualmente
# Edit os arquivos, depois:
git add .
git commit

# 3. Re-aplicar patches
.kanban-patches/scripts/apply-patches.sh

# 4. Push
git push origin HEAD
```

### Patches Não Aplicam

Se os patches falharem (Chatwoot mudou muito):

```bash
# Ver o que o patch quer fazer
cat .kanban-patches/patches/001-redis-keys.patch

# Aplicar manualmente:
# 1. Abrir lib/redis/redis_keys.rb
# 2. Adicionar as linhas do Kanban
# 3. Commit
git add lib/redis/redis_keys.rb
git commit -m "fix: manually apply Kanban patches"
```

## 🎯 Próximos Passos

1. **Agora:** O sistema já está ativo! Espere os PRs automáticos
2. **Quando aparecer PR:** Revise e aprove
3. **Após merge:** Reinicie o servidor
4. **Pronto!** Kanban funcionando na nova versão

## 💡 Dicas

- **Teste primeiro:** Se tiver staging, teste o PR lá antes de produção
- **Leia changelogs:** Sempre leia o que mudou no Chatwoot
- **Mantenha patches:** Se Chatwoot mudar muito, atualize os patches
- **Backup antes:** Sempre faça backup antes de atualizar produção

## 🌟 Benefícios

- ⚡ **Zero trabalho manual** na maioria dos casos
- 🔒 **Seguro** - sempre revisa antes de aplicar
- 📝 **Documentado** - tudo explicado
- 🧪 **Testado** - roda testes automaticamente
- 🔄 **Reversível** - fácil voltar atrás se necessário

## 📞 Suporte

Se tiver problemas:

1. Leia `.kanban-patches/docs/USAGE.md`
2. Leia `.kanban-patches/docs/CHANGES.md`
3. Veja os patches em `.kanban-patches/patches/`
4. Teste em branch separada primeiro

---

## 🎉 Resumo Final

**Você criou um sistema que:**

✅ Checa atualizações do Chatwoot automaticamente
✅ Aplica patches do Kanban automaticamente
✅ Testa tudo automaticamente
✅ Cria PRs prontos para revisar
✅ Documenta tudo perfeitamente

**Seu trabalho agora é:**

1. Esperar PRs aparecerem
2. Revisar e aprovar
3. Fazer merge
4. Reiniciar servidor

**É isso! 🚀**

---

*Sistema criado em 8 de Março de 2026*
*Última atualização: 8 de Março de 2026*
