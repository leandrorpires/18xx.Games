# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18Junta
      module Step
        # Private (I): before a coup is counted its owner may discard one of the alignment tokens of
        # the corporation.
        class CoupPrivateIChoice < Engine::Step::Base
          ACTIONS = %w[choose].freeze
          SKIP_CHOICE = 'skip'

          def description
            'Private (I): Discard Token'
          end

          def actions(entity)
            return [] unless entity
            return [] unless entity == pending_actor

            ACTIONS
          end

          def active_entities
            actor = pending_actor
            actor ? [actor] : super
          end

          def blocks?
            !pending_actor.nil?
          end

          def choice_name
            'Private (I) Orejuela Abogados: discard 1 alignment token?'
          end

          def choices
            corp = @game.pending_coup_i_choice
            return {} unless corp

            alignment = @game.corporation_alignment(corp)
            choice_hash = { SKIP_CHOICE => 'Do not discard' }
            choice_hash['civilian'] = "Discard 1 Civilian token (has #{alignment[:civilian]})" if alignment[:civilian].positive?
            choice_hash['military'] = "Discard 1 Military token (has #{alignment[:military]})" if alignment[:military].positive?
            choice_hash
          end

          def process_choose(action)
            @game.resolve_private_i_choice!(action.choice)
            pass!
          end

          private

          def pending_actor
            @game.pending_coup_i_choice&.owner
          end
        end
      end
    end
  end
end
