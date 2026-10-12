# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18Junta
      module Step
        # Building on an unclaimed paramilitary hex: the corporation supports the civilian or military
        # side (moving the political track) or discards the token with Private (C).
        class ParamilitaryChoice < Engine::Step::Base
          ACTIONS = %w[choose].freeze

          def description
            'Paramilitary Token'
          end

          def actions(entity)
            return [] unless entity == current_entity
            return [] unless @game.pending_paramilitary_choice_for?(entity)

            ACTIONS
          end

          def blocks?
            @game.pending_paramilitary_choice_for?(current_entity)
          end

          def choice_name
            hex = @game.pending_paramilitary_hex
            "A paramilitary group was identified at #{hex&.name}: which side will the company support now?"
          end

          def choices
            choice_hash = {
              'civilian' => 'Support the Civilian side',
              'military' => 'Support the Military side',
            }
            if @game.discard_paramilitary_free?(current_entity)
              choice_hash['discard'] = 'Discard the token without choosing a side [Private (C)]'
            end
            choice_hash
          end

          def process_choose(action)
            @game.resolve_paramilitary_choice!(action.entity, action.choice)
          end
        end
      end
    end
  end
end
