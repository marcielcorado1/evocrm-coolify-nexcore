# 🔧 Kit de Correções EvoCRM — Custom Tools + Google Calendar

Pacote para aplicar, em **qualquer instalação nova do EvoCRM**, os 6 bugfixes que fazem as **ferramentas customizadas (HTTP tools)** e a **integração Google Calendar** dos agentes funcionarem de verdade.

> Feito para reuso nas instalações dos alunos do ecossistema **NexCore**.
> Patches criados e validados em produção em 2026-07-03.

---

## 📦 O que tem no pacote

```
evocrm-fixes/
├── README.md                       ← este arquivo
├── aplicar-correcoes-evocrm.sh     ← script que aplica tudo automático
└── patches/
    ├── tool_builder.py             ← 3 fixes (schema flat+aninhado, assinatura real, values no body)
    ├── agent_service.py            ← 1 fix (get_custom_tools com db)
    └── custom_tool_service.py      ← 1 fix (query no model SQLAlchemy)
```

Todos os patches ficam no serviço **`processor`** (`evo-ai-processor-community`). Os demais serviços do EvoCRM (crm, frontend, auth, etc.) são originais — não precisam de alteração.

---

## 🚀 Como aplicar (numa VPS com EvoCRM já instalado)

1. Copie a pasta `evocrm-fixes` inteira para a VPS onde o EvoCRM roda.
2. No terminal da VPS:
   ```bash
   cd evocrm-fixes
   chmod +x aplicar-correcoes-evocrm.sh
   ./aplicar-correcoes-evocrm.sh
   ```
3. O script detecta sozinho se é **Docker Swarm** ou **Compose**, faz backup, aplica os fixes, cria a imagem `evoapicloud/evo-ai-processor-community:oracle-hotfix` e atualiza o serviço.

### ⚠️ Passo final obrigatório (pra não perder o fix num redeploy)
Edite o compose/stack do EvoCRM e troque a imagem do **processor**:
```yaml
# de:
image: evoapicloud/evo-ai-processor-community:latest
# para:
image: evoapicloud/evo-ai-processor-community:oracle-hotfix
```
- **Swarm:** `docker stack deploy -c SEU_COMPOSE.yml --resolve-image never NOME_STACK`
- **Compose:** `docker compose up -d --force-recreate <servico_processor>`

Sem isso, um `deploy` futuro puxa o `:latest` original e reverte as correções.

---

## 🐞 Os 6 bugs corrigidos

| # | Bug | Sintoma | Arquivo |
|---|-----|---------|---------|
| 1 | `custom_tool_service.get_custom_tool()` não existe | tools da UI carregam 0 ("Added 0 tools from custom_tool_ids") | agent_service.py |
| 2 | `get_custom_tools()` chamado sem `db` | reconstrução das tools crasha silenciosa | agent_service.py |
| 3 | Query usa schema Pydantic em vez do model SQLAlchemy | "Column expression... got CustomTool" | custom_tool_service.py |
| 4 | `_create_http_tool` só lê params aninhados (`parameters.*`) | tools salvas no formato flat da UI viram `(**kwargs)` sem schema | tool_builder.py |
| 5 | `values` (url, type) iam na query string em POST | EvoGo responde "URL is required" (mídia não envia) | tool_builder.py |
| 6 | Função `(**kwargs)` → schema vazio pro LLM | o modelo chama a tool sem passar argumentos ({}) | tool_builder.py |

**Resultado após o fix:** agentes conseguem enviar imagem/vídeo/PDF via HTTP tool, consultar CEP/APIs externas, e usar a integração Google Calendar (check_availability + create_event).

---

## 📅 Sobre a integração Google Calendar

O **código** do Google Calendar já vem no processor original — os fixes acima não mexem nele. Mas para um agente **usar** a agenda, é preciso, por agente, preencher `config.integrations`:

- `google-calendar`: `{ "connected": true, "settings": { ... } }`
- `google-calendar-credentials`: `{ access_token, refresh_token, token_uri, client_id, client_secret, scopes }`

⚠️ **Formato do `settings` (senão crasha `'int' object has no attribute 'get'`):**
```json
{
  "timezone": "America/Sao_Paulo",
  "calendarId": "email-da-agenda@gmail.com",
  "businessHours": {
    "enabled": true,
    "monday":    {"enabled": true, "start": "08:00", "end": "18:00"},
    "tuesday":   {"enabled": true, "start": "08:00", "end": "18:00"},
    "wednesday": {"enabled": true, "start": "08:00", "end": "18:00"},
    "thursday":  {"enabled": true, "start": "08:00", "end": "18:00"},
    "friday":    {"enabled": true, "start": "08:00", "end": "18:00"},
    "saturday":  {"enabled": true, "start": "08:00", "end": "12:00"},
    "sunday":    {"enabled": false, "start": "08:00", "end": "12:00"}
  },
  "minAdvanceTime": {"enabled": true, "value": 2, "unit": "hours"},
  "maxDuration":    {"value": 2, "unit": "hours"},
  "sendInvitations": true
}
```
`minAdvanceTime` e `maxDuration` DEVEM ser objetos (não números). `businessHours` como acima.

### Como obter as credenciais (OAuth manual)
A tela de conexão do Google na UI do EvoCRM ainda está "em desenvolvimento". Enquanto isso, conecte manualmente:
1. Google Cloud Console → criar projeto → ativar **Google Calendar API**.
2. Tela de consentimento OAuth → **Publicar app** (produção, senão o token expira em 7 dias).
3. Credenciais → **ID do cliente OAuth** → tipo **App para computador** → copiar `client_id` e `client_secret`.
4. Montar o link de autorização (scope `calendar.events calendar.readonly`, `redirect_uri=http://localhost`, `access_type=offline`, `prompt=consent`), abrir logado na conta da agenda, autorizar, copiar a URL `http://localhost/?code=...`.
5. Trocar o `code` por tokens em `https://oauth2.googleapis.com/token` (grant_type=authorization_code) → guardar o `refresh_token`.
6. Injetar `google-calendar` + `google-calendar-credentials` no `config.integrations` do agente (via API PUT /agents/{id} ou banco).

---

## 🧪 Como validar que funcionou

1. Crie uma custom tool num agente (ex: consultar CEP via ViaCEP) e converse com ele pedindo pra usar.
2. Se a integração Google estiver configurada, peça pra marcar uma visita e veja o evento cair na agenda.
3. Logs do processor: `docker logs <container_processor> | grep -iE "custom tool|Google Calendar|Error executing"`.

---

## ↩️ Rollback

O script guarda o backup dos originais em `/app/oracle-backup-AAAAMMDD-HHMMSS/` dentro do container.
Para voltar ao original: aponte o compose de novo para `:latest` e faça o deploy, OU restaure os arquivos do backup e recommit.

---

## 📌 Compatibilidade

Patches validados contra a imagem `evoapicloud/evo-ai-processor-community` (versão de 2026-07-03, base `:latest` digest `sha256:abd7d118...`). Se a Evolution lançar uma versão nova do processor com mudanças grandes nesses arquivos, revise os patches antes de aplicar. O ideal permanente é a Evolution mergear esses fixes no projeto oficial.
