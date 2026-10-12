# frozen_string_literal: true

require_relative '../../../step/buy_company'

module Engine
  module Game
    module G18Junta
      module Step
        # Validates before buying so that a rejected purchase leaves no partial effect: private (L)
        # cannot be sold to a corporation and only the president's privates can be bought.
        class BuyCompany < Engine::Step::BuyCompany
          def process_buy_company(action)
            entity = action.entity
            company = action.company
            raise GameError, "#{company.name} cannot be sold to a company" if @game.abilities(company, :no_buy)
            if entity.corporation? && company.owner != entity.owner
              raise GameError, "#{entity.name} can only buy Private Companies from its president (#{entity.owner&.name})"
            end

            super
          end
        end
      end
    end
  end
end
