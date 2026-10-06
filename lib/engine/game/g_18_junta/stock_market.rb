# frozen_string_literal: true

require_relative '../../stock_market'

module Engine
  module Game
    module G18Junta
      # rev. 2.9 (lote C), manual 4.3.3: quando o marcador precisa subir e já
      # está na linha mais alta, ele anda um espaço para a direita. Vale para
      # o "acima" do dividendo alto, para a companhia toda vendida e para o
      # "direita" no fim de uma linha (que o motor transforma em "acima").
      # Na última casa da linha mais alta ($350, fim de jogo) fica parado.
      # Sem a regra nova (jogos antigos), o movimento é o do motor.
      class StockMarket < Engine::StockMarket
        def initialize(market, unlimited_types, top_row_right: false, **opts)
          @top_row_right = top_row_right
          super(market, unlimited_types, **opts)
        end

        def up(corporation, coordinates)
          return super unless @top_row_right && top_row?(coordinates)
          return coordinates if max_share_price?(coordinates)

          [coordinates[0], coordinates[1] + 1]
        end
      end
    end
  end
end
