# frozen_string_literal: true

require_relative '../../../step/special_track'
require_relative 'track_hooks'

module Engine
  module Game
    module G18Junta
      module Step
        # Trilho extra da privada (F) Ingeniería Real (18Junta Regras 4.1 e
        # 11): a partir da rev. 2.8, só um trilho AMARELO em hexágono vazio
        # (nunca upgrade), e o trilho passa pelos mesmos ganchos do Track do
        # 18Junta: o procedimento do paramilitar (licença e corrupção só
        # valem para upgrades, que a (F) não faz mais). Jogos anteriores à
        # rev. 2.8 mantêm o comportamento do SpecialTrack do motor.
        class SpecialTrack < Engine::Step::SpecialTrack
          include TrackHooks

          def potential_tiles(entity_or_entities, hex)
            tiles = super
            return tiles unless private_f_restricted?(Array(entity_or_entities).first)
            return [] unless hex.tile.color == :white

            tiles.select { |t| t.color == :yellow }
          end

          def process_lay_tile(action)
            entity = action.entity
            return super unless private_f_restricted?(entity)

            unless action.hex.tile.color == :white && action.tile.color == :yellow
              raise GameError, "#{entity.name} can only lay a yellow tile on an empty hex"
            end

            super

            # Sem upgrade não há licença a consumir nem ficha de corrupção
            # (consume_license_if_upgraded não teria efeito); resta o
            # paramilitar, resolvido pela companhia dona da (F).
            flag_paramilitar_hex_if_needed(action, entity.owner)
          end

          private

          def private_f_restricted?(entity)
            @game.rev_2_8? && entity&.company? && entity.sym == '(F)' && entity.owner&.corporation?
          end
        end
      end
    end
  end
end
