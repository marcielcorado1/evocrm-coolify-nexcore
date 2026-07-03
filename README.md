# 🚀 EvoCRM no Coolify — Instalação passo a passo (para leigos)

Este repositório instala o **EvoCRM completo** (com as correções da NexCore já embutidas) em qualquer VPS que tenha o **Coolify**. Serve tanto para migrar quanto para alunos montarem o próprio do zero.

> ✅ Já vem tudo junto: banco de dados (PostgreSQL), Redis e todos os serviços do EvoCRM.
> ✅ As correções de bugs (custom tools + Google Calendar) entram automaticamente.
> ✅ Você não precisa inventar senhas — o Coolify gera sozinho.

---

## ⚡ Guia Rápido (7 passos)

Se você já manja de Coolify, é só isso. (O passo a passo detalhado, com telas, está mais abaixo.)

1. **DNS primeiro** — crie 2 registros **A** apontando pro IP da VPS (faça isso ANTES de deployar, senão o SSL falha):
   - `crm.seudominio.com.br` → IP da VPS
   - `api-crm.seudominio.com.br` → IP da VPS

2. **Firewall** — abra só as portas **80, 443** (e 22 pro SSH). Nenhuma porta interna vai pro firewall.

3. **Coolify** → **+ New Resource → Docker Compose → Public Repository** → cole:
   `https://github.com/marcielcorado1/evocrm-coolify-nexcore` → branch `main` → Load.

4. **Domínios** (⚠️ atenção na porta do gateway):
   | Serviço | Domínio |
   |---|---|
   | frontend | `https://crm.seudominio.com.br` |
   | gateway | `https://api-crm.seudominio.com.br` **`:3030`** |

   > ⚠️ **Não esqueça o `:3030`** no gateway — é a porta interna. Sem isso, a API dá `502`.

5. **1 variável** — em Environment Variables, adicione `ENCRYPTION_KEY` gerada com:
   `openssl rand -base64 32 | tr '+/' '-_'`   *(o resto das senhas o Coolify gera sozinho.)*

6. **Deploy** → espere ~3-5 min (na primeira vez baixa imagens + roda migrações).

7. Abra `https://crm.seudominio.com.br` → **crie a conta de admin** → pronto! 🎉

### 🎯 As 2 únicas pegadinhas (o resto é automático)
- **DNS antes do deploy** (senão o SSL não é emitido).
- **`:3030` no domínio do gateway** (senão `502` na API).

---

## ✅ O que você precisa antes de começar

1. **Uma VPS com Coolify instalado** (se não tem, instale em https://coolify.io — é um comando só).
2. **Dois subdomínios** apontando para o IP da sua VPS (registro tipo **A** no seu provedor de domínio):
   - `crm.seudominio.com.br` → o painel (você acessa aqui)
   - `api-crm.seudominio.com.br` → a API (o painel conversa com ela)

   > 💡 Se não tiver domínio, o Coolify também gera domínios automáticos `.sslip.io` — dá pra testar sem domínio próprio.

---

## 📦 Passo 1 — Criar o recurso no Coolify

1. Entre no seu Coolify.
2. Escolha um **Projeto** (ou crie um novo) → **+ New Resource**.
3. Escolha **Docker Compose** → **Public Repository**.
4. Cole a URL deste repositório:
   ```
   https://github.com/marcielcorado1/evocrm-coolify-nexcore
   ```
5. Em **Branch**, deixe `main`. Clique em **Load / Continue**.

O Coolify vai ler o `docker-compose.yaml` e mostrar os serviços.

---

## 🌐 Passo 2 — Definir os domínios

O Coolify vai listar os serviços. Você precisa dar domínio para **dois** deles:

| Serviço | Domínio que você coloca | Porta |
|---------|-------------------------|-------|
| **frontend** | `crm.seudominio.com.br` | 80 |
| **gateway** | `api-crm.seudominio.com.br` | 3030 |

- Procure o campo **Domains** de cada serviço e coloque o domínio (com `https://`).
- Os outros serviços **não** precisam de domínio (são internos).

> 💡 Se for usar os domínios automáticos do Coolify, é só clicar em "Generate Domain" em cada um.

---

## 🔑 Passo 3 — Definir a chave de criptografia

Na aba **Environment Variables** do recurso, adicione **uma** variável:

- **Nome:** `ENCRYPTION_KEY`
- **Valor:** gere com **um** dos comandos abaixo (rode no seu computador ou no terminal da VPS):

  ```bash
  # Opção A (openssl — funciona em quase toda VPS):
  openssl rand -base64 32 | tr '+/' '-_'

  # Opção B (python):
  python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
  ```

  Copie o resultado (algo como `ORlRr4PtE6vBpetgjrnWxU5phiGoSoYllV3Smd_t97I=`) e cole no valor.

> ⚠️ **Guarde essa chave!** Se ela mudar depois, dados criptografados (tokens de integração) param de funcionar. Todas as outras senhas o Coolify gera e guarda sozinho.

---

## ▶️ Passo 4 — Deploy

1. Clique em **Deploy**.
2. A primeira subida demora alguns minutos (baixa as imagens e roda as migrações do banco).
3. Acompanhe os logs — quando o `frontend` e o `gateway` ficarem verdes, está no ar.

---

## 🎉 Passo 5 — Primeiro acesso

1. Abra `https://crm.seudominio.com.br`
2. Crie a primeira conta (cadastro de administrador).
3. Pronto! Já pode criar seus agentes de IA.

---

## 🔧 As correções que já vêm aplicadas

O serviço **processor** é construído pelo Coolify a partir do `processor.Dockerfile`, que copia 4 arquivos corrigidos da pasta `patches/` por cima da imagem oficial (os fixes ficam embutidos na imagem):

| Arquivo | Corrige |
|---------|---------|
| `tool_builder.py` | ferramentas HTTP (enviar imagem/vídeo/PDF, consultar APIs) + Google Calendar |
| `agent_service.py` | carregamento das ferramentas customizadas |
| `custom_tool_service.py` | consulta das ferramentas no banco |
| `database.py` | conexão do banco (sslmode) |

Com isso, as **custom tools** e a **integração Google Calendar** dos agentes funcionam de verdade — coisa que na versão oficial ainda está com bug.

> Detalhes técnicos dos bugs e da integração Google Calendar: veja `patches/SOBRE-OS-FIXES.md`.

---

## 🆘 Problemas comuns

| Sintoma | Solução |
|---------|---------|
| **API (gateway) dá `502 Bad Gateway`** | ⚠️ **O mais comum!** O gateway escuta na porta interna **3030**. Ao definir o domínio da API no Coolify, use a porta no final: **`https://api-crm.seudominio.com.br:3030`** — o `:3030` diz ao Coolify pra entregar o tráfego na porta interna certa (o público continua 443, sem porta). Sem isso, o Traefik manda pra porta 80 e dá 502. |
| Painel abre mas não loga / erro de CORS | Confira se os domínios `frontend` e `gateway` estão certos e com `https://` |
| "Deploy failed" logo no começo | Veja se os 2 subdomínios estão apontando pro IP da VPS (DNS propagado) |
| Agente responde mas não usa ferramentas | O processor é buildado do `processor.Dockerfile` — confirme que o build rodou (não é bind mount) |
| Integração Google Calendar não aparece | Ela é configurada por agente (OAuth manual) — veja `patches/SOBRE-OS-FIXES.md` |

> 💡 **Resumo das portas nos domínios (Coolify):**
> - **frontend** → `https://crm.seudominio.com.br` (porta 80, padrão — não precisa especificar)
> - **gateway** → `https://api-crm.seudominio.com.br:3030` (⚠️ precisa do `:3030`)
>
> No firewall/security list da VPS, abra **somente 80 e 443** (+ 22 SSH e a do Coolify). As portas internas (3030, 3000, 5432, etc.) **não** vão pro firewall — o Traefik cuida delas na rede interna do Docker.

---

## ♻️ Atualizando

Quando a Evolution lançar uma versão nova, os `patches/` podem precisar de ajuste (foram validados em 2026-07). Se algo quebrar após atualizar as imagens, é só reverter para as imagens da época ou revisar os patches.

---

*Feito pela NexCore 🟢 — ecossistema de automação com IA.*
