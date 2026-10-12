# frozen_string_literal: true

require_relative '../../../step/track'
require_relative 'track_hooks'

module Engine
  module Game
    module G18Junta
      module Step
        # Track step with the 18Junta rules: tile colors limited by phase, upgrade licenses and
        # paramilitary hexes.
        class Track < Engine::Step::Track
          include TrackHooks

          def process_lay_tile(action)
            color = action.tile.color
            unless @game.phase.tiles.include?(color)
              raise GameError, "#{color.to_s.capitalize} tiles are not available in phase #{@game.phase.name}"
            end

            super

            consume_license_if_upgraded(action)
            flag_paramilitary_hex_if_needed(action)
            expire_license_if_turn_ended(action.entity)
          end

          def process_pass(action)
            super

            @game.expire_upgrade_license_if_unused!(action.entity)
          end

          def skip!
            entity = current_entity
            super
            @game.expire_upgrade_license_if_unused!(entity) if entity&.corporation?
          end

          private

          def expire_license_if_turn_ended(entity)
            return if can_lay_tile?(entity)

            @game.expire_upgrade_license_if_unused!(entity)
          end
        end
      end
    end
  end
end
