# frozen_string_literal: true

require_relative '../../../step/special_track'
require_relative 'track_hooks'

module Engine
  module Game
    module G18Junta
      module Step
        # Private (F) extra track: yellow only, on an empty hex.
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

            if action.hex.tile.color != :white || action.tile.color != :yellow
              raise GameError, "#{entity.name} can only lay a yellow tile on an empty hex"
            end

            super

            flag_paramilitary_hex_if_needed(action, entity.owner)
          end

          private

          def private_f_restricted?(entity)
            entity&.company? && entity.sym == '(F)' && entity.owner&.corporation?
          end
        end
      end
    end
  end
end
