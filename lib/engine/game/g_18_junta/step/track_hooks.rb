# frozen_string_literal: true

module Engine
  module Game
    module G18Junta
      module Step
        # Shared by the normal track step and the Private (F) track: upgrade license use, corruption
        # token draw and paramilitary hex flag.
        module TrackHooks
          private

          def consume_license_if_upgraded(action, corporation = action.entity, upgraded: @round.upgraded_track)
            return unless upgraded

            if @game.consume_upgrade_license!(corporation)
              @log << "#{corporation.name} uses the Upgrade License (does not draw a corruption token)"
            else
              draw_corruption_token_for_upgrade!(corporation)
            end
          end

          def draw_corruption_token_for_upgrade!(entity)
            president = entity.owner
            colors = @game.draw_corruption_tokens!(president, max_draws: 1, corporation: entity)
            return if colors.empty?

            color_name = colors.first == :white ? 'white' : 'black'
            @log << "#{president.name} receives a random corruption token for upgrading without a license: "\
                    "Drew a #{color_name} token"
          end

          def flag_paramilitary_hex_if_needed(action, corporation = action.entity)
            hex = action.hex
            return unless @game.paramilitary_hex_unclaimed?(hex)

            @game.flag_paramilitary_hex_pending!(hex, corporation)
          end
        end
      end
    end
  end
end
