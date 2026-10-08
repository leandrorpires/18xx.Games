# frozen_string_literal: true

require_relative '../../../step/special_choose'

module Engine
  module Game
    module G18Junta
      module Step
        # Private (M) Sociedade Caja Negra: once per Stock Round, on its owner's
        # turn, the owner may draw 1 corruption token from the bag and receive
        # $5 times the current phase number from the bank. It is a free action:
        # the step never blocks and never passes, so the owner's turn goes on
        # (buy, sell or pass) after using it.
        #
        # Like the other player-owned privates, the ability is driven by the
        # generic choose_ability action on the company, so the existing
        # "Abilities:" panel of the game page shows the button (no new view).
        class PrivateMDraw < Engine::Step::SpecialChoose
          DRAW_CHOICE = 'draw'

          def actions(entity)
            return [] unless entity&.company?
            return [] unless entity.sym == '(M)'
            return [] unless @game.private_m_usable?(entity.owner)
            return [] unless entity.owner == current_entity

            ACTIONS
          end

          def description
            'Private (M): Draw Corruption Token'
          end

          def choices_ability(entity)
            return {} unless actions(entity).any?

            payment = @game.format_currency(@game.private_m_payment)
            { DRAW_CHOICE => "Draw 1 corruption token from the bag and receive #{payment} from the bank" }
          end

          def process_choose_ability(action)
            entity = action.entity
            raise GameError, 'Private (M) cannot be used now' unless actions(entity).any?
            raise GameError, "Invalid Private (M) choice: #{action.choice}" unless action.choice == DRAW_CHOICE

            @game.use_private_m!(entity.owner)
          end
        end
      end
    end
  end
end
