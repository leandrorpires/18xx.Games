# frozen_string_literal: true

require_relative '../../../step/buy_sell_par_shares'

module Engine
  module Game
    module G18Junta
      module Step
        # Privada (A): se o preço de Oferta Inicial de uma companhia já foi
        # fixado (ver FixParPrice), só esse preço pode ser usado ao parar a
        # companhia de verdade -- ninguém mais escolhe livremente.
        class BuySellParShares < Engine::Step::BuySellParShares
          def get_par_prices(entity, corporation)
            fixed = @game.fixed_par_price_for(corporation)
            return [fixed] if fixed

            super
          end

          # rev. 2.8 (BUG-13/14): o motor valida o preço de abertura que a
          # interface já restringe -- o fixado pela (A), se houver; senão um
          # preço de par oferecido por get_par_prices. A validação vem antes
          # do super, para não deixar o preço de par gravado na companhia.
          def process_par(action)
            if @game.rev_2_8?
              price = action.share_price
              valid = get_par_prices(action.entity, action.corporation)
              unless price && valid.any? { |p| p.price == price.price && p.coordinates == price.coordinates }
                fixed = @game.fixed_par_price_for(action.corporation)
                raise GameError, "#{action.corporation.name} has its par price fixed at "\
                                 "#{@game.format_currency(fixed.price)} (Private (A))" if fixed
                raise GameError, "Invalid par price: #{price ? @game.format_currency(price.price) : 'none'}"
              end
            end

            super
          end
        end
      end
    end
  end
end
