# CRM com patches de compatibilidade aplicados em build-time (padrão do processor).
# Patches: webhook aceita data vazio + parse de QR aceita casing novo do EvoGo.
# Ver patches/crm_boot_patches.rb (idempotente).
FROM evoapicloud/evo-ai-crm-community:latest
COPY patches/crm_boot_patches.rb /tmp/crm_boot_patches.rb
RUN ruby /tmp/crm_boot_patches.rb && rm /tmp/crm_boot_patches.rb
