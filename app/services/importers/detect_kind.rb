# frozen_string_literal: true

module Importers
  class DetectKind
    # Retorna um símbolo do tipo de documento: :linkedin ou :cv
    #
    # Uso esperado no seu código atual:
    #   kind = Importers::DetectKind.call(text: texto, hint: @source)
    #
    # Regras:
    # - Se 'hint' vier como :linkedin ou :cv, respeita o hint (curto-circuito)
    # - Caso contrário, tenta detectar pelo conteúdo do texto extraído
    # - Heurísticas leves e baratas (não dependem de IA)
    #
    # Retorno: :linkedin ou :cv
    def self.call(text:, hint: nil)
      # Curto-circuito pelo 'hint' quando for explícito
      if %i[linkedin cv].include?(hint)
        return hint
      end

      t = text.to_s

      # Sinais fortes de export do LinkedIn
      return :linkedin if t.match?(/linkedin\.com\/in/i)
      return :linkedin if t.match?(/\btop\s+skills\b/i)
      return :linkedin if t.match?(/\brecommendations?\b/i)
      return :linkedin if t.match?(/\babout\b/i) && t.match?(/\bexperience\b/i) && t.match?(/\beducation\b/i)

      # Alguns PDFs de LinkedIn trazem "—" entre empresa e cargo
      return :linkedin if t.include?(" — ") && t.match?(/\bexperience\b/i)

      # Fallback genérico
      :cv
    end
  end
end
