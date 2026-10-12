# frozen_string_literal: true

require_relative '../../../step/dividend'

module Engine
  module Game
    module G18Junta
      module Step
        # Dividends: withhold moves left, payout moves right, payout of at least twice the share price
        # moves right and up. Private (H) pays a bonus on a high payout.
        class Dividend < Engine::Step::Dividend
          def share_price_change(entity, revenue = 0)
            return { share_direction: :left, share_times: 1 } unless revenue.positive?
            return { share_direction: :right, share_times: 1 } unless revenue >= entity.share_price.price * 2

            { share_direction: %i[right up], share_times: [1, 1] }
          end

          def process_dividend(action)
            entity = action.entity
            revenue = total_revenue

            if action.kind.to_s == 'payout' && @game.owns_private?(entity, '(H)') &&
               entity.share_price && revenue >= entity.share_price.price * 2
              pay_private_h_bonus!(entity, revenue)
            end

            super
          end

          private

          def pay_private_h_bonus!(entity, revenue)
            bonus = (revenue * 0.10).round
            return unless bonus.positive?

            @game.bank.spend(bonus, entity)
            @log << "#{entity.name} receives #{@game.format_currency(bonus)} extra from the bank for paying a high dividend "\
                    '[Private (H) Gutiérrez y Asociados].'
          end
        end
      end
    end
  end
end
