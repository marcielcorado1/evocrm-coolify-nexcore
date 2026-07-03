# Imagem do processor do EvoCRM com as correções NexCore já embutidas.
# O Coolify constrói esta imagem a partir do repositório (build context = raiz do repo),
# copiando os 4 arquivos corrigidos por cima da imagem oficial.
#
# Vantagem sobre bind mount: funciona no Coolify (que resolve mounts em outro diretório),
# fica embutido na imagem e é portátil.

FROM evoapicloud/evo-ai-processor-community:latest

# --- correções (custom tools + Google Calendar + conexão de banco) ---
COPY patches/tool_builder.py        /app/src/services/adk/tool_builder.py
COPY patches/agent_service.py       /app/src/services/agent_service.py
COPY patches/custom_tool_service.py /app/src/services/custom_tool_service.py
COPY patches/database.py            /app/src/config/database.py
