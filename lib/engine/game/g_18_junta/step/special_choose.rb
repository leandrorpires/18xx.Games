# frozen_string_literal: true

require_relative '../../../step/special_choose'

module Engine
  module Game
    module G18Junta
      module Step
        # Abilities of Private (N), (D) and (E) through the generic choose_ability action.
        class SpecialChoose < Engine::Step::SpecialChoose
          def choices_ability(entity)
            case entity.sym
            when '(N)'
              @game.remaining_paramilitary_hexes.to_h { |hex_id| [hex_id, "Remove token at #{hex_id}"] }
            when '(D)'
              corporation = entity.owner
              target = @game.private_d_target_train
              return {} unless target

              discardable_trains(corporation).to_h do |old_train|
                next [old_train.id, nil] unless target.price > old_train.price

                final_price = [target.price - old_train.price, 0].max
                [old_train.id, "Discard #{old_train.name} to buy #{target.name} for "\
                               "#{@game.format_currency(final_price)} (instead of "\
                               "#{@game.format_currency(target.price)})"]
              end.compact
            when '(E)'
              corporation = current_entity
              return {} unless @game.private_e_donatable?(corporation)

              { 'donate' => "Donate to #{corporation.name} (receives #{@game.format_currency(150)} from the bank)" }
            else
              {}
            end
          end

          def process_choose_ability(action)
            entity = action.entity

            case entity.sym
            when '(N)'
              @game.use_private_n!(entity.owner, action.choice)
              @game.abilities(entity, :choose_ability).use!
            when '(D)'
              corporation = entity.owner
              old_train = discardable_trains(corporation).find { |t| t.id == action.choice }
              # a coup triggered by the new train closes this private, so fetch the ability first
              ability = @game.abilities(entity, :choose_ability)
              @game.exchange_train_for_private_d!(corporation, old_train) if old_train
              ability.use!
            when '(E)'
              corporation = current_entity
              @game.donate_private_e!(corporation) if @game.private_e_donatable?(corporation)
            end
          end

          private

          def discardable_trains(corporation)
            corporation.trains.select { |t| %w[2 3].include?(t.name) }
          end
        end
      end
    end
  end
end
