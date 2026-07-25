# Auto-patches do EvoCRM — executado no boot do serviço crm (command do compose).
# Vive no volume evocrm_storage para sobreviver a redeploys.
# Idempotente: só altera se o padrão antigo existir.
PATCHES = [
  {
    file: '/app/app/controllers/webhooks/whatsapp_controller.rb',
    subs: [["params[:data].present? &&", "!params[:data].nil? &&"]]
  },
  {
    file: '/app/app/controllers/api/v1/evolution_go/qrcodes_controller.rb',
    subs: [
      ["parsed_response['data']['Qrcode']", "(parsed_response['data']['Qrcode'] || parsed_response['data']['qrcode'])"],
      ["parsed_response['data']['Code']",   "(parsed_response['data']['Code'] || parsed_response['data']['code'])"]
    ]
  }
]

PATCHES.each do |p|
  next unless File.exist?(p[:file])
  s = File.read(p[:file])
  changed = false
  p[:subs].each do |old, new|
    next if s.include?(new)   # já aplicado
    next unless s.include?(old)
    s = s.gsub(old, new)
    changed = true
  end
  # fallback do parse fora de data (qrcodes_controller)
  if p[:file].include?('qrcodes')
    s2 = s.gsub(/parsed_response\['Qrcode'\](?! \|\|)/, "(parsed_response['Qrcode'] || parsed_response['qrcode'])")
    s2 = s2.gsub(/parsed_response\['Code'\](?! \|\|)/, "(parsed_response['Code'] || parsed_response['code'])")
    changed ||= (s2 != s)
    s = s2
  end
  if changed
    File.write(p[:file], s)
    puts "[boot_patches] aplicado: #{p[:file]}"
  else
    puts "[boot_patches] ok (já aplicado): #{p[:file]}"
  end
end
