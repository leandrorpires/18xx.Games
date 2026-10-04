# frozen_string_literal: true

require_relative '../../../step/buy_company'

module Engine
  module Game
    module G18Junta
      module Step
        # Compra de privada por companhia (18Junta Regras 2.2 e 11): a partir
        # da rev. 2.8, o motor valida o que a interface já restringe -- só se
        # compra privada do próprio presidente, e a (L) nunca é vendida a uma
        # companhia. A validação vem antes do super, para que uma compra
        # rejeitada não deixe efeito parcial.
        class BuyCompany < Engine::Step::BuyCompany
          def process_buy_company(action)
            if @game.rev_2_8?
              entity = action.entity
              company = action.company
              raise GameError, "#{company.name} não pode ser vendida para uma companhia" if @game.abilities(company, :no_buy)
              if entity.corporation? && company.owner != entity.owner
                raise GameError, "#{entity.name} só pode comprar privadas do seu presidente (#{entity.owner&.name})"
              end
            end

            super
          end
        end
      end
    end
  end
end
