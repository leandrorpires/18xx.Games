# frozen_string_literal: true

require_relative 'entities'
require_relative 'map'
require_relative 'map_2p'
require_relative 'meta'
require_relative 'step/coup_private_i_choice'
require_relative 'step/dividend'
require_relative 'step/paramilitary_choice'
require_relative 'step/private_auction'
require_relative 'step/track'
require_relative 'step/upgrade_license'
require_relative 'step/fix_par_price'
require_relative 'step/buy_sell_par_shares'
require_relative 'step/buy_company'
require_relative 'step/special_track'
require_relative '../base'
require_relative 'step/special_choose'
require_relative 'step/private_m_draw'
require_relative 'stock_market'

module Engine
  module Game
    module G18Junta
      class Game < Game::Base
        include_meta(G18Junta::Meta)
        include Entities
        include Map

        def optional_hexes
          two_player? ? Map2P::HEXES_2P : game_hexes
        end

        STATION_TOKENS = { 'E' => [0, 40, 80], 'V' => [0, 40] }.freeze

        def game_corporations
          corporations = self.class::CORPORATIONS
          if two_player?
            corporations = corporations.map { |corp| corp[:sym] == 'C' ? corp.merge(coordinates: 'F4') : corp }
          end
          corporations.map do |corp|
            tokens = self.class::STATION_TOKENS[corp[:sym]]
            tokens ? corp.merge(tokens: tokens) : corp
          end
        end

        def location_name(coord)
          two_player? ? Map2P::LOCATION_NAMES_2P[coord] : self.class::LOCATION_NAMES[coord]
        end

        CURRENCY_FORMAT_STR = '$%s'

        BANK_CASH = { 2 => 5_000, 3 => 7_000, 4 => 7_000 }.freeze

        CERT_LIMIT = { 2 => 22, 3 => 16, 4 => 14 }.freeze

        STARTING_CASH = { 2 => 580, 3 => 520, 4 => 450 }.freeze

        CAPITALIZATION = :full

        MUST_SELL_IN_BLOCKS = false

        SELL_BUY_ORDER = :sell_buy_sell

        POOL_SHARE_LIMIT = 50

        SOLD_OUT_INCREASE = true

        GAME_END_CHECK = { bankrupt: :immediate, bank: :full_or, stock_market: :current_or }.freeze

        MARKET = [
          %w[75 85 95 105 115 130 145 160 180 205 230 260 290 320 350e],
          %w[70 80 90 100 110 125 140 155 175 200 225 250 275 300 330e],
          %w[65 70 80 90 100p 110 125 140 155 175 200 225 250 280],
          %w[55 65 70 80p 90p 100 110 125 140 155 175 200],
          %w[50 55 65 70p 80 90 100 110 125 140],
          %w[45 50 60 65p 70 80 90 100],
          %w[35 45 55 60 65 70],
          %w[25 35 45 55],
          %w[10 25 35],
        ].freeze

        PHASES = [
          {
            name: '2',
            train_limit: 4,
            tiles: [:yellow],
            operating_rounds: 1,
          },
          {
            name: '3',
            on: '3',
            train_limit: 4,
            tiles: %i[yellow green],
            operating_rounds: 2,
            status: ['can_buy_companies'],
          },
          {
            name: '4',
            on: '4',
            train_limit: 3,
            tiles: %i[yellow green],
            operating_rounds: 2,
            status: ['can_buy_companies'],
          },
          {
            name: '5',
            on: '5',
            train_limit: 2,
            tiles: %i[yellow green brown],
            operating_rounds: 3,
            status: %w[can_buy_companies coup_attempt],
          },
          {
            name: '6',
            on: '6',
            train_limit: 2,
            tiles: %i[yellow green brown],
            operating_rounds: 3,
          },
          {
            name: '8',
            on: '8',
            train_limit: 2,
            tiles: %i[yellow green brown],
            operating_rounds: 3,
          },
          {
            name: 'D',
            on: 'D',
            train_limit: 2,
            tiles: %i[yellow green brown gray],
            operating_rounds: 3,
          },
        ].freeze

        TRAINS = [
          { name: '2', distance: 2, price: 80, rusts_on: '4', num: 6 },
          { name: '3', distance: 3, price: 180, rusts_on: '6', num: 5 },
          { name: '4', distance: 4, price: 300, rusts_on: %w[8 D], num: 4 },
          { name: '5', distance: 5, price: 450, num: 3 },
          { name: '6', distance: 6, price: 630, num: 2 },
          {
            name: '8',
            distance: 8,
            price: 900,
            num: 6,
            available_on: '6',
            discount: { '4' => 150, '5' => 150, '6' => 150 },
          },
          {
            name: 'D',
            distance: 999,
            price: 1_100,
            num: 6,
            available_on: '6',
            discount: { '4' => 300, '5' => 300, '6' => 300 },
          },
        ].freeze

        STATUS_TEXT = Base::STATUS_TEXT.merge(
          'coup_attempt' => [
            'Coup Attempt',
            'Each 5-train bought reveals the top card of the Political Situation deck '\
            '(three cards: 2 Calm and 1 Coup Attempt). The coup is resolved when the Coup Attempt card appears.',
          ],
        ).freeze

        EBUY_PRES_SWAP = false
        EBUY_FROM_OTHERS = :value
        ALLOW_TRAIN_BUY_FROM_OTHER_PLAYERS = false
        HOME_TOKEN_TIMING = :float

        CORRUPTION_BAG_INITIAL = { white: 28, black: 7 }.freeze
        CORRUPTION_REFILL_ON_TRAIN_DEPLETED = {
          '2' => { white: 0, black: 3 },
          '3' => { white: 0, black: 3 },
          '4' => { white: 0, black: 3 },
        }.freeze

        PRIVATES_IN_PLAY = { 2 => 5, 3 => 6, 4 => 7 }.freeze

        CORRUPTION_INDEMNITY_TABLE = [
          { max: 15, dictatorship: 12, democracy: 20 },
          { max: 20, dictatorship: 16, democracy: 25 },
          { max: 25, dictatorship: 20, democracy: 30 },
          { max: 30, dictatorship: 24, democracy: 35 },
          { max: 35, dictatorship: 28, democracy: 40 },
          { max: 40, dictatorship: 32, democracy: 45 },
          { max: 45, dictatorship: 36, democracy: 50 },
          { max: 50, dictatorship: 40, democracy: 55 },
          { max: Float::INFINITY, dictatorship: 44, democracy: 60 },
        ].freeze

        POLITICAL_TRACK_LIMIT = 5
        RADICAL_THRESHOLD = 3

        MILITARY_BONUS_PER_TOKEN = 80

        # Private (G): towns do not count toward the distance of the owning company's trains (they still pay).
        def check_distance(route, visits, train = nil)
          train ||= route.train
          distance = train.distance

          if distance.is_a?(Numeric) && route.corporation && owns_private?(route.corporation, '(G)')
            route_distance = visits.sum { |v| v.town? ? 0 : v.visit_cost }
            raise RouteTooLong, "#{route_distance} is too many stops for #{distance} train" if distance < route_distance

            return
          end

          super
        end

        # Route text shown on the route selection screen: farms are shown as a single symbol, towns
        # ignored by (G) in brackets.
        def revenue_str(route)
          stops = route.visited_stops

          farm_hexes = stops.select { |stop| farm_stop?(stop) }.map(&:hex)

          village_bonus_hexes = stops.select do |stop|
            stop.respond_to?(:town?) && stop.town? && route.corporation && owns_private?(route.corporation, '(G)')
          end.map(&:hex)

          route.hexes.map do |hex|
            if farm_hexes.include?(hex)
              'Ⓕ'
            elsif village_bonus_hexes.include?(hex)
              "[#{hex.name}]"
            else
              hex.name
            end
          end.join('+')
        end

        def route_distance_str(route)
          used = route_distance(route)
          train_distance = route.train.distance
          exceeded = train_distance.is_a?(Numeric) && used > train_distance
          exceeded ? "#{used}*" : used.to_s
        end

        def check_other(route)
          stops = route.visited_stops
          return if stops.empty?

          raise GameError, 'A farm cannot be the start or the end of a route' if farm_stop?(stops.first) || farm_stop?(stops.last)
        end

        # Farm tiles are the ones whose label is a single space (the label only exists to tie farm
        # tiles to farm hexes).
        def farm_stop?(stop)
          stop.tile.label.to_s == ' '
        end

        def stock_round
          # (M) comes first: it is a free action, so it must stay available even while a
          # blocking step (e.g. the Private (A) question) is waiting for the owner.
          Round::Stock.new(self, [
            G18Junta::Step::PrivateMDraw,
            G18Junta::Step::FixParPrice,
            Engine::Step::DiscardTrain,
            Engine::Step::Exchange,
            Engine::Step::SpecialTrack,
            G18Junta::Step::BuySellParShares,
          ])
        end

        def operating_round(round_num)
          @or_round_number += 1
          expire_stale_upgrade_licenses!

          Round::Operating.new(self, [
            G18Junta::Step::CoupPrivateIChoice,
            Engine::Step::Bankrupt,
            Engine::Step::Exchange,
            G18Junta::Step::SpecialTrack,
            G18Junta::Step::SpecialChoose,
            G18Junta::Step::BuyCompany,
            G18Junta::Step::ParamilitaryChoice,
            G18Junta::Step::Track,
            G18Junta::Step::UpgradeLicense,
            Engine::Step::Token,
            Engine::Step::Route,
            G18Junta::Step::Dividend,
            Engine::Step::DiscardTrain,
            Engine::Step::BuyTrain,

            [G18Junta::Step::BuyCompany, { blocks: true }],
          ], round_num: round_num)
        end

        # Initial setup: corruption bag, political track, political situation deck and the random
        # private/corporation selection.
        def setup
          @or_round_number = 0
          @upgrade_licenses = {}
          @coup_resolved = false
          @private_n_used = false
          @pending_coup_i_choice = nil
          @private_d_used = false
          @private_k_swap_or = nil
          @private_m_used_turn = nil

          setup_corruption_bag!
          setup_political_track!
          @political_situation_deck = %i[calm calm coup].sort_by { rand }

          @private_a_used = false
          @fixed_par_prices = {}
        end

        TOP_ROW_RIGHT_SYMBOL = "\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0↱"

        # Top-row cells show an arrow: moving 'up' from the top row moves one cell to the right
        # instead (see stock_market.rb).
        def game_market
          market = self.class::MARKET
          top_row = market.first.each_with_index.map do |code, col|
            next code if col == market.first.size - 1 || code.match?(/[a-zA-Z]/)

            { price: code.to_i, info: self.class::TOP_ROW_RIGHT_SYMBOL }
          end
          [top_row, *market.drop(1)]
        end

        def init_stock_market
          G18Junta::StockMarket.new(game_market, self.class::CERT_LIMIT_TYPES,
                                    multiple_buy_types: self.class::MULTIPLE_BUY_TYPES,
                                    sold_out_top_row_movement: self.class::SOLD_OUT_TOP_ROW_MOVEMENT)
        end

        def game_trains
          trains = self.class::TRAINS
          return trains unless two_player?

          trains.map do |train|
            if %w[2 3 4].include?(train[:name])
              train.merge(num: train[:num] - 1)
            else
              train
            end
          end
        end

        # Removes one random corporation and keeps only the random set of private companies in play.
        def select_game_entities!
          return if @game_entities_selected

          @game_entities_selected = true
          @setup_log = []

          if two_player?
            h_corp = @corporations.find { |c| c.name == 'H' }
            if h_corp
              @corporations.delete(h_corp)
              @setup_log << '2-Player Game (smaller Map): Corporation H not available'
            end
          end

          removed_corporation = @corporations.min_by { rand }
          @corporations.delete(removed_corporation)
          @setup_log << "Corporation removed in this game: #{removed_corporation.name}"

          available_companies = @companies.reject { |c| c.meta[:present] == :never }
          privates_in_play = self.class::PRIVATES_IN_PLAY[players.size]
          forced = available_companies.select { |c| c.meta[:present] }
          remaining_pool = (available_companies - forced).sort_by { rand }
          selected = forced + remaining_pool.take(privates_in_play - forced.size)
          (@companies - selected).each { |c| remove_company(c) }
          @setup_log << "Private companies available in this game: #{selected.map(&:name).join(', ')}"
        end

        def remove_company(company)
          company.close!
          @companies.delete(company)
        end

        # Corruption bag: 28 white and 7 black tokens, shuffled with the game's random generator.
        def setup_corruption_bag!
          @corruption_bag = []
          self.class::CORRUPTION_BAG_INITIAL.each { |color, count| count.times { @corruption_bag << color } }
          @corruption_bag.sort_by! { rand }
          @corruption_tokens = Hash.new { |h, k| h[k] = { white: 0, black: 0 } }
        end

        def log_cost_discount(spender, abilities, discount)
          return unless discount.positive?

          @log << "#{spender.name} receives a discount of "\
                  "#{format_currency(discount)} from "\
                  "#{Array(abilities).map { |a| a.owner.name }.uniq.join(', ')}"
        end

        # Only a train bought from the depot offer reveals a political situation card (5-train) and
        # depletes its pile.
        def buy_train(operator, train, price = nil)
          from_depot = @depot.upcoming.include?(train)
          depleting = from_depot && @depot.upcoming.count { |t| t.name == train.name } == 1
          super
          refill_corruption_bag!(train.name) if depleting
          reveal_political_situation_card! if train.name == '5' && from_depot && !coup_resolved?
        end

        # When the last train of a type (2, 3 or 4) is bought, black tokens are added to the corruption bag.
        def refill_corruption_bag!(train_name)
          refill = self.class::CORRUPTION_REFILL_ON_TRAIN_DEPLETED[train_name]
          return unless refill

          refill.each { |color, count| count.times { @corruption_bag << color } }
          @corruption_bag.sort_by! { rand }
          white = refill[:white]
          black = refill[:black]
          @log << if white.positive?
                    "#{train_name}-train exhausted: #{white} white token(s) and #{black} black token(s) "\
                      'are added to the corruption bag'
                  else
                    "#{train_name}-train exhausted: #{black} black token(s) are added to the corruption bag"
                  end
        end

        # With an empty bag the token comes black from the general stock.
        def draw_corruption_token!
          if @corruption_bag.empty?
            @log << 'Corruption bag empty: the token comes black from the stock'
            return :black
          end

          @corruption_bag.pop
        end

        # Hands a corruption token to a player; Private (K) may swap a black token drawn from the bag.
        def give_corruption_token!(holder, color, corporation: nil)
          return color unless holder

          color = swap_black_via_private_k(holder, corporation) if color == :black && corporation

          @corruption_tokens[holder][color] += 1
          color
        end

        def corruption_tokens(holder)
          @corruption_tokens[holder]
        end

        def player_card_rows(player)
          tokens = corruption_tokens(player)
          ['Corruption:', "#{tokens[:white]}x◯  #{tokens[:black]}x⚫"]
        end

        def corruption_bag_summary
          tally = @corruption_bag.tally
          { white: tally[:white] || 0, black: tally[:black] || 0 }
        end

        def coup_resolved?
          @coup_resolved
        end

        # Private (K): once per Operating Round, a black token drawn by the president goes back to the
        # bag and a new one is drawn and kept.
        def swap_black_via_private_k(holder, corporation)
          return :black unless corporation.owner == holder
          return :black unless owns_private?(corporation, '(K)')
          return :black if @private_k_swap_or == @or_round_number

          @private_k_swap_or = @or_round_number
          @corruption_bag << :black
          @corruption_bag.sort_by! { rand }
          new_color = @corruption_bag.pop
          color_name = new_color == :white ? 'white' : 'black'
          @log << "#{holder.name} returns the black token to the bag and draws another: #{color_name} "\
                  '(Private (K) Hernandez Abogados)'
          new_color
        end

        # Political situation deck: two calm cards and one coup attempt; the coup is resolved immediately.
        def reveal_political_situation_card!
          card = @political_situation_deck.shift
          return unless card

          if card == :calm
            @log << 'Political Situation card: Calm — the game continues normally.'
          else
            @log << 'Political Situation card: COUP ATTEMPT!'
            start_coup_attempt!
          end
        end

        attr_reader :coup_outcome, :pending_paramilitary_hex, :pending_coup_i_choice, :political_track

        # Regime indicated by the political track (military side: dictatorship; civilian or neutral: democracy).
        def track_regime
          @political_track.negative? ? :dictatorship : :democracy
        end

        # Coup attempt: the outcome (democracy or dictatorship) is decided by the alignment tokens of
        # the floated corporations.
        def start_coup_attempt!
          @coup_outcome = track_regime

          i_owner = @corporations.find { |c| owns_private?(c, '(I)') }
          if i_owner
            @pending_coup_i_choice = i_owner
          else
            finalize_coup_attempt!
          end
        end

        def resolve_private_i_choice!(choice)
          corp = @pending_coup_i_choice
          if corp && %w[civilian military].include?(choice)
            side = choice.to_sym
            if @corporation_alignment[corp][side].positive?
              @corporation_alignment[corp][side] -= 1
              @log << "#{corp.name} discards 1 #{choice == 'civilian' ? 'Civilian' : 'Military'} token "\
                      '(Private (I) Orejuela Abogados)'
            end
          end
          @pending_coup_i_choice = nil
          finalize_coup_attempt!
        end

        # Applies the coup outcome: closes private companies, removes a train type and punishes the
        # least aligned corporation.
        def finalize_coup_attempt!
          @coup_resolved = true
          outcome_label = @coup_outcome == :dictatorship ? 'DICTATORSHIP' : 'DEMOCRACY'

          @log << '-------------------------------------------------------------'
          @log << '-------------------------------------------------------------'
          @log << '-------------------  𝐂𝐎𝐔𝐏 𝐀𝐓𝐓𝐄𝐌𝐏𝐓 -------------------'
          @log << '-------------------------------------------------------------'
          @log << "Coup Attempt Result: #{outcome_label}"
          @log << '-------------------------------------------------------------'
          @log << '-------------------------------------------------------------'

          cancel_alignment_token_pairs!

          if @coup_outcome == :democracy
            apply_democracy_effects!
          else
            apply_dictatorship_effects!
          end

          close_all_private_companies!
        end

        def close_all_private_companies!
          @log << '-------------------------------------------------------------'
          @log << 'OTHER EFFECTS:'
          replace_border_hexes_for_dictatorship! if @coup_outcome == :dictatorship
          clear_remaining_paramilitary_icons!
          @companies.dup.each { |c| remove_company(c) }
          @log << 'All Private Companies close, without compensation to the owners.'
          @log << '-------------------------------------------------------------'
          @log << '-------------------------------------------------------------'
        end

        def clear_remaining_paramilitary_icons!
          return if @paramilitary_hexes_remaining.empty?

          @paramilitary_hexes_remaining.each { |hex_id| remove_paramilitary_icon!(hex_by_id(hex_id)) }
          @paramilitary_hexes_remaining = []
          @log << 'The remaining paramilitary tokens are removed from the board.'
        end

        def cancel_alignment_token_pairs!
          @corporation_alignment.each_value do |alignment|
            pairs = [alignment[:civilian], alignment[:military]].min
            alignment[:civilian] -= pairs
            alignment[:military] -= pairs
          end
        end

        def floated_corporations
          @corporations.select(&:floated?)
        end

        def apply_democracy_effects!
          remove_train_type_from_depot!('8')
          remove_phase!('8')

          benefited = floated_corporations.select { |corp| @corporation_alignment[corp][:civilian].positive? }
          unless benefited.empty?
            @log << 'BENEFITED:'
            benefited.each do |corp|
              blue = @corporation_alignment[corp][:civilian]
              blue.times { stock_market.move_right(corp) }
              @log << "#{corp.name} - (#{blue} CIVILIAN token(s)). Moves #{blue} space(s) right on the stock market."
            end
          end

          punish_least_aligned!(:democracy)
        end

        def apply_dictatorship_effects!
          remove_train_type_from_depot!('D')

          benefited = floated_corporations.select { |corp| @corporation_alignment[corp][:military].positive? }
          unless benefited.empty?
            @log << 'BENEFITED:'
            benefited.each do |corp|
              green = @corporation_alignment[corp][:military]
              amount = green * self.class::MILITARY_BONUS_PER_TOKEN
              @bank.spend(amount, corp)
              @log << "#{corp.name} receives #{format_currency(amount)} from the bank (#{green} Military token(s))"
            end
          end

          punish_least_aligned!(:dictatorship)
        end

        def remove_train_type_from_depot!(train_name)
          @depot.upcoming.select { |t| t.name == train_name }.dup.each { |t| @depot.remove_train(t) }
        end

        def remove_phase!(phase_name)
          return if @phase.name == phase_name

          @phase.phases.reject! { |phase| phase[:name] == phase_name }
          @phase.next_on = Array(@phase.upcoming&.dig(:on))
        end

        def game_phases
          self.class::PHASES.dup
        end

        def replace_border_hexes_for_dictatorship!
          border_tiles = two_player? ? Map2P::DICTATORSHIP_BORDER_TILES_2P : self.class::DICTATORSHIP_BORDER_TILES
          border_tiles.each do |hex_id, code|
            hex = hex_by_id(hex_id)
            next unless hex

            old_tile = hex.tile
            new_tile = Tile.from_code(hex_id, :red, code)
            update_tile_lists(new_tile, old_tile)
            hex.lay(new_tile)
          end
          clear_graph
        end

        # The corporation least aligned with the winning side is punished; ties go to the first
        # corporation in operating order.
        def punish_least_aligned!(outcome)
          corps = floated_corporations
          return if corps.empty?

          net_alignment = lambda do |corp|
            alignment = @corporation_alignment[corp]
            outcome == :democracy ? alignment[:civilian] - alignment[:military] : alignment[:military] - alignment[:civilian]
          end

          min_value = corps.map(&net_alignment).min
          candidates = corps.select { |c| net_alignment.call(c) == min_value }
          target = candidates.min

          outcome == :democracy ? devalue_company!(target) : punish_dictatorship_dissenter!(target)
        end

        # Democracy punishment: share price moves to the lowest market value that is at least half of
        # the current price.
        def devalue_company!(corporation)
          return unless corporation.share_price

          new_price = find_share_price_at_or_above_half(corporation.share_price.price)
          return unless new_price

          @log << '------------------------------------------------------------'
          @log << 'PUNISHMENT:'
          @log << "#{corporation.name} (least aligned with the winner) loses share price."
          stock_market.move(corporation, new_price.coordinates, force: true)
          @log << "Its share price drops to #{format_currency(new_price.price)}"

          log_direct_effects_democracy!
        end

        def log_direct_effects_democracy!
          @log << '------------------------------------------------------------'
          @log << 'DIRECT EFFECTS:'
          @log << 'Last train type available: D (8-trains removed from the game).'
          @log << 'Higher corruption cost at game end.'
        end

        # Smallest market value >= half of the current price; among equal cells the rightmost, then
        # the highest, is used.
        def find_share_price_at_or_above_half(current_price)
          candidates = stock_market.market.flatten.compact.select { |sp| sp.price * 2 >= current_price }
          return nil if candidates.empty?

          min_price = candidates.map(&:price).min
          candidates.select { |sp| sp.price == min_price }.min_by { |sp| [-sp.coordinates[1], sp.coordinates[0]] }
        end

        def punish_dictatorship_dissenter!(corporation)
          @log << '------------------------------------------------------------'
          @log << 'PUNISHMENT:'
          @log << "#{corporation.name} (least aligned with the winner) is persecuted by the new government."

          president = corporation.owner
          if president
            @corruption_tokens[president][:black] += 10
            @log << "Its president (#{president.name}) receives 10 black corruption tokens."
          end

          log_direct_effects_dictatorship!
        end

        def log_direct_effects_dictatorship!
          @log << '------------------------------------------------------------'
          @log << 'DIRECT EFFECTS:'
          @log << 'Border city hexes (A13, D4, L12 and K3) have their revenue changed.'
          @log << 'Last train type available: 8 (D-trains and gray tiles removed from the game).'
          @log << 'Lower corruption cost at game end.'
        end

        def owns_private?(corporation, private_sym)
          corporation.companies.any? { |c| c.sym == private_sym }
        end

        def end_game!(game_end_reason)
          return if @finished

          pay_corruption_indemnity!
          super
        end

        def total_corruption_tokens
          @corruption_tokens.values.sum { |tokens| tokens[:white] + tokens[:black] }
        end

        def corruption_indemnity_rate
          total = total_corruption_tokens
          return 0 if total.zero?

          outcome = @coup_outcome || track_regime
          row = self.class::CORRUPTION_INDEMNITY_TABLE.find { |r| total <= r[:max] }
          row[outcome]
        end

        # End of game: each player pays the table rate for every black token held (rate depends on the
        # coup outcome).
        def pay_corruption_indemnity!
          rate = corruption_indemnity_rate
          return unless rate.positive?

          outcome = @coup_outcome || track_regime
          @log << "-- Corruption penalty: #{total_corruption_tokens} token(s) in total, "\
                  "#{format_currency(rate)} per black token (#{outcome == :dictatorship ? 'Dictatorship' : 'Democracy'}) --"

          @corruption_tokens.each do |player, tokens|
            next unless tokens[:black].positive?

            amount = rate * tokens[:black]
            player.spend(amount, @bank, check_cash: false, check_positive: false)
            @log << "#{player.name} pays #{format_currency(amount)} corruption penalty "\
                    "(#{tokens[:black]} black token(s))"
          end
        end

        # Starts the political track at neutral and draws the four corporations that begin with an
        # alignment token.
        def setup_political_track!
          @political_track = 0
          @corporation_alignment = Hash.new { |h, k| h[k] = { civilian: 0, military: 0 } }
          @initial_alignment_applied_to_track = {}
          @paramilitary_hexes_remaining = (two_player? ? Map2P::PARAMILITARY_HEXES_2P : self.class::PARAMILITARY_HEXES).dup
          @pending_paramilitary_choice = nil
          @pending_paramilitary_hex = nil

          military_corps, civilian_corps = @corporations.sort_by { rand }.first(4).each_slice(2).to_a
          military_corps.each { |c| @corporation_alignment[c][:military] += 1 }
          civilian_corps.each { |c| @corporation_alignment[c][:civilian] += 1 }
          tokens = military_corps.map { |c| "#{c.name} (Military)" } + civilian_corps.map { |c| "#{c.name} (Civilian)" }
          (@setup_log ||= []) << "Starting corporation alignment tokens: #{tokens.join(', ')}."
          flush_setup_log!
        end

        SETUP_LOG_RULE = "#{'-' * 31} SETUP #{'-' * 32}".freeze
        SETUP_LOG_END = '-' * 70

        # Writes the setup block of the log: phase line, SETUP section, phase line.
        def flush_setup_log!
          privates, others = @setup_log.partition { |line| line.start_with?('Private companies') }
          lines = others + privates
          @setup_log = []
          idx = @log.index { |e| e.message.to_s.start_with?('-- Phase ') }
          phase_text = idx ? @log.delete_at(idx).message : nil

          @log << phase_text if phase_text
          @log << SETUP_LOG_RULE
          lines.each { |line| @log << line }
          @log << SETUP_LOG_END
          @log << phase_text if phase_text
        end

        def float_corporation(corporation)
          super
          apply_initial_alignment_to_track!(corporation)
        end

        def apply_initial_alignment_to_track!(corporation)
          return if @initial_alignment_applied_to_track[corporation]

          @initial_alignment_applied_to_track[corporation] = true
          alignment = @corporation_alignment[corporation]
          move_political_track!(:civilian, corporation) if alignment[:civilian].positive?
          move_political_track!(:military, corporation) if alignment[:military].positive?
        end

        def paramilitary_hex_unclaimed?(hex)
          @paramilitary_hexes_remaining.include?(hex.id)
        end

        def flag_paramilitary_hex_pending!(hex, corporation)
          @paramilitary_hexes_remaining.delete(hex.id)
          remove_paramilitary_icon!(hex)
          @pending_paramilitary_choice = corporation
          @pending_paramilitary_hex = hex
        end

        def remove_paramilitary_icon!(hex)
          hex.tile.icons.reject! { |icon| icon.name == 'militia' }
        end

        def pending_paramilitary_choice_for?(entity)
          @pending_paramilitary_choice == entity
        end

        def discard_paramilitary_free?(corporation)
          return false unless corporation.respond_to?(:companies)

          corporation.companies.any? { |c| c.sym == '(C)' }
        end

        def resolve_paramilitary_choice!(corporation, choice)
          hex = @pending_paramilitary_hex
          @pending_paramilitary_choice = nil
          @pending_paramilitary_hex = nil

          case choice
          when 'discard'
            @log << "#{corporation.name} discards the paramilitary token at #{hex.name} without choosing a side [Private (C)]"
          when 'civilian', 'military'
            side = choice.to_sym
            @corporation_alignment[corporation][side] += 1
            move_political_track!(side, corporation)
            side_name = side == :civilian ? 'Civilian' : 'Military'
            @log << "#{corporation.name} supports the #{side_name} side at #{hex.name}"
            colors = draw_corruption_tokens!(corporation.owner, max_draws: 2, corporation: corporation)
            drawn_side_name = side == :civilian ? 'Civilian' : 'Military'
            unless colors.empty?
              @log << "#{corporation.owner.name} draws corruption token(s) for supporting the #{drawn_side_name} side"\
                      ": #{corruption_tokens_summary_text(colors)}"
            end
          else
            raise GameError, "Invalid paramilitary choice: #{choice}"
          end
        end

        def draw_corruption_tokens!(president, max_draws:, corporation: nil)
          colors = []

          max_draws.times do
            from_bag = !@corruption_bag.empty?
            color = draw_corruption_token!
            break unless color

            final_color = give_corruption_token!(president, color, corporation: from_bag ? corporation : nil)
            colors << final_color
            break if final_color == :black
          end

          colors
        end

        def corruption_tokens_summary_text(colors)
          ordinals = %w[1st 2nd 3rd 4th]
          parts = colors.each_with_index.map do |color, index|
            color_name = color == :white ? 'white' : 'black'
            "#{ordinals[index]} #{color_name}"
          end
          "#{parts.join(', ')}."
        end

        def corporation_alignment(corporation)
          @corporation_alignment[corporation]
        end

        # Moves the marker; from 3 spaces on one side a move to the other side counts double, never
        # stops on neutral and is limited to +-5. Once the coup is resolved the track is locked.
        def move_political_track!(side, corporation)
          if coup_resolved?
            @log << "Political track is locked after the coup: #{corporation.name}'s "\
                    "#{side == :civilian ? 'Civilian' : 'Military'} token does not move the marker."
            return
          end

          limit = self.class::POLITICAL_TRACK_LIMIT
          threshold = self.class::RADICAL_THRESHOLD
          radical_opposite = side == :civilian ? @political_track <= -threshold : @political_track >= threshold
          delta = (radical_opposite ? 2 : 1) * (side == :civilian ? 1 : -1)
          new_position = @political_track + delta
          new_position += (side == :civilian ? 1 : -1) if new_position.zero? && !@political_track.zero?
          @political_track = new_position.clamp(-limit, limit)
          @log << "Political Track now at #{political_track_label}"

          display_political_track_label = political_track_label.gsub(/\A\s*-+\s*|\s*-+\s*\z/, '')
          hex_by_id('A2').tile.location_name = "STATUS: \n#{display_political_track_label}"
          hex_by_id('A2').tile.color = political_track_tile_color
        end

        def political_track_label
          political_track_label_for(@political_track)
        end

        # Color of the A2 status tile: orange when neutral, green on the military side, blue on the
        # civilian side.
        def political_track_tile_color
          return :orange if @political_track.zero?

          @political_track.negative? ? :green : :blue
        end

        # The A2 status tile only shows the political track and is never upgraded.
        def upgrades_to?(from, to, special = false, selected_company: nil)
          return false if from.hex&.id == 'A2'

          super
        end

        def political_track_label_for(position)
          return 'NEUTRAL' if position.zero?

          position.positive? ? "--- CIV #{position}" : "MIL #{position.abs} ---"
        end

        def political_track_positions
          limit = self.class::POLITICAL_TRACK_LIMIT
          (-limit..limit).to_a
        end

        # Extra lines on the corporation card: alignment tokens, fixed par price and upgrade license.
        def status_array(corporation)
          alignment = @corporation_alignment[corporation]
          return unless alignment

          status = []
          status << ["Civilian x#{alignment[:civilian]}", 'civilian_support'] if alignment[:civilian].positive?
          status << ["Military x#{alignment[:military]}", 'military_support'] if alignment[:military].positive?

          fixed_price = fixed_par_price_for(corporation)
          if fixed_price && !corporation.ipoed
            status << ["_____________________Fixed Par Price: #{format_currency(fixed_price.price)}",
                       'fixed_par_price']
          end

          status << ['____________________(Upgrade License acquired)', 'upgrade_license'] if upgrade_license_granted?(corporation)

          status
        end

        # Mathematical Bold letters, used to fake bold in the plain-text Info panel.
        BOLD_CHARS = {
          'A' => '𝐀',
          'B' => '𝐁',
          'C' => '𝐂',
          'D' => '𝐃',
          'E' => '𝐄',
          'F' => '𝐅',
          'G' => '𝐆',
          'H' => '𝐇',
          'I' => '𝐈',
          'J' => '𝐉',
          'K' => '𝐊',
          'L' => '𝐋',
          'M' => '𝐌',
          'N' => '𝐍',
          'O' => '𝐎',
          'P' => '𝐏',
          'Q' => '𝐐',
          'R' => '𝐑',
          'S' => '𝐒',
          'T' => '𝐓',
          'U' => '𝐔',
          'V' => '𝐕',
          'W' => '𝐖',
          'X' => '𝐗',
          'Y' => '𝐘',
          'Z' => '𝐙',
          'a' => '𝐚',
          'b' => '𝐛',
          'c' => '𝐜',
          'd' => '𝐝',
          'e' => '𝐞',
          'f' => '𝐟',
          'g' => '𝐠',
          'h' => '𝐡',
          'i' => '𝐢',
          'j' => '𝐣',
          'k' => '𝐤',
          'l' => '𝐥',
          'm' => '𝐦',
          'n' => '𝐧',
          'o' => '𝐨',
          'p' => '𝐩',
          'q' => '𝐪',
          'r' => '𝐫',
          's' => '𝐬',
          't' => '𝐭',
          'u' => '𝐮',
          'v' => '𝐯',
          'w' => '𝐰',
          'x' => '𝐱',
          'y' => '𝐲',
          'z' => '𝐳',
          '0' => '𝟎',
          '1' => '𝟏',
          '2' => '𝟐',
          '3' => '𝟑',
          '4' => '𝟒',
          '5' => '𝟓',
          '6' => '𝟔',
          '7' => '𝟕',
          '8' => '𝟖',
          '9' => '𝟗',
        }.freeze

        # Bold look-alike for short labels; characters without a bold form are kept as they are.
        def bold_text(text)
          text.gsub(/[A-Za-z0-9]/, BOLD_CHARS)
        end

        def corruption_counts(white, black)
          "#{white}x\u26AA  #{black}x\u26AB"
        end

        # End-game penalty per black token, built from CORRUPTION_INDEMNITY_TABLE.
        def corruption_penalty_table_line
          low = 1
          self.class::CORRUPTION_INDEMNITY_TABLE.map do |row|
            range = if row[:max] == Float::INFINITY
                      "#{bold_text(low.to_s)}+"
                    elsif low == 1
                      "<=#{bold_text(row[:max].to_s)}"
                    else
                      "#{bold_text(low.to_s)}\u2013#{bold_text(row[:max].to_s)}"
                    end
            low = row[:max] + 1
            "#{range}: #{format_currency(row[:dictatorship])}/#{format_currency(row[:democracy])}"
          end.join(' | ')
        end

        # Lines of the "Timeline" section of the Info page: political track, then the corruption bag
        # and the corruption tokens held by each player. The marker leaves the neutral position on its
        # first move and never comes back, so NEUTRAL is only listed while the marker is still there.
        def timeline
          bag = corruption_bag_summary
          scale = political_track_positions.filter_map do |position|
            next if position.zero? && @political_track != 0

            label = political_track_label_for(position).delete('-').strip
            label = position == @political_track ? "\u25B6#{bold_text(label)}\u25C0" : label
            if position <= -self.class::RADICAL_THRESHOLD
              "#{label} >>"
            elsif position >= self.class::RADICAL_THRESHOLD
              "<< #{label}"
            else
              label
            end
          end
          held = @players.map do |player|
            tokens = corruption_tokens(player)
            "#{player.name}:  #{corruption_counts(tokens[:white], tokens[:black])}"
          end

          [
            "#{bold_text('POLITICAL TRACK')}: #{political_track_label.delete('-').strip}",
            scale.join(' | '),
            "\u00A0",
            "#{bold_text('CORRUPTION')}:",
            "BAG:  #{corruption_counts(bag[:white], bag[:black])}",
            *held,
            "#{bold_text('End-game Corruption Penalty')} ($ per black token) - Dictatorship / Democracy",
            corruption_penalty_table_line,
          ]
        end

        def remaining_paramilitary_hexes
          @paramilitary_hexes_remaining
        end

        def private_a_usable_this_stock_round?
          !@private_a_used
        end

        def private_a_owner
          owner = @companies.find { |c| c.sym == '(A)' }&.owner
          owner if owner&.player?
        end

        # Private (A): once per game, fixes the par price of a corporation that has not been started.
        def use_private_a!(corporation, share_price)
          @private_a_used = true
          @fixed_par_prices[corporation] = share_price
          @log << "#{corporation.name} has its par price fixed at "\
                  "#{format_currency(share_price.price)} (Private (A) Investidores Unidos)"
        end

        def skip_private_a!(player)
          @log << "#{player.name} does not use Private (A) Investidores Unidos in this Stock Round"
        end

        def fixed_par_price_for(corporation)
          @fixed_par_prices[corporation]
        end

        DONATE_PRIVATE_E_FEE = 150

        # Private (E): from phase 3 its owner may donate it to a corporation he presides over.
        def private_e_donatable?(corporation)
          return false unless corporation
          return false unless @phase.status.include?('can_buy_companies')

          owner = @companies.find { |c| c.sym == '(E)' }&.owner
          owner&.player? && corporation.owner == owner
        end

        # Private (M) Sociedade Caja Negra: free action, once per Stock Round, on the
        # owner's turn. Draws 1 token from the (already shuffled) corruption bag and
        # pays $5 x phase number. Not available in phase D, with an empty bag, or when
        # the private is owned by a company or closed.
        def private_m_payment
          5 * @phase.name.to_i
        end

        def private_m_usable?(player)
          return false unless player&.player?
          return false unless @round.is_a?(Engine::Round::Stock)
          return false if @private_m_used_turn == @turn
          return false if @phase.name == 'D'
          return false if @corruption_bag.empty?

          company = @companies.find { |c| c.sym == '(M)' }
          !company.nil? && !company.closed? && company.owner == player
        end

        # Private (M): once per Stock Round the owner draws a token and gets $5 times the phase number
        # from the bank.
        def use_private_m!(player)
          raise GameError, 'Private (M) cannot be used now' unless private_m_usable?(player)

          @private_m_used_turn = @turn
          amount = private_m_payment
          color = draw_corruption_token!
          give_corruption_token!(player, color)
          @bank.spend(amount, player)
          @log << "#{player.name} uses Private (M) Sociedade Caja Negra: draws a #{color == :white ? 'white' : 'black'} "\
                  "corruption token and receives #{format_currency(amount)} from the bank"
        end

        def donate_private_e!(corporation)
          company = @companies.find { |c| c.sym == '(E)' }
          owner = company.owner

          owner.companies.delete(company)
          company.owner = corporation
          corporation.companies << company
          @bank.spend(self.class::DONATE_PRIVATE_E_FEE, corporation)

          @log << "#{owner.name} donates Private #{company.name} to #{corporation.name}. The company receives "\
                  "#{format_currency(self.class::DONATE_PRIVATE_E_FEE)} from the bank."
        end

        # Private (D) only buys new trains from the supply; discarded trains in the depot do not count.
        def private_d_target_train
          @depot.available_upcoming_trains.min_by(&:price)
        end

        # Private (D): once per game, discards a 2- or 3-train and buys the cheapest depot train
        # paying only the difference.
        def exchange_train_for_private_d!(corporation, old_train)
          new_train = private_d_target_train
          return unless new_train

          unless new_train.price > old_train.price
            raise GameError,
                  'WARNING: The exchange is only possible for a train of higher value than the discarded train!'
          end

          final_price = [new_train.price - old_train.price, 0].max

          @private_d_used = true

          corporation.trains.delete(old_train)
          @depot.forget_train(old_train)

          source = new_train.owner
          @log << "#{corporation.name} discards a #{old_train.name}-train and buys a #{new_train.name}-train for "\
                  "#{format_currency(final_price)} (Private (D) Ferramenteria Ochoa)"

          buy_train(corporation, new_train, final_price.positive? ? final_price : :free)
          @phase.buying_train!(corporation, new_train, source)
        end

        # Private (N): once per game removes a paramilitary token; the president takes two black
        # tokens from the general stock.
        def use_private_n!(corporation, hex_id)
          @private_n_used = true
          @paramilitary_hexes_remaining.delete(hex_id)
          remove_paramilitary_icon!(hex_by_id(hex_id))

          president = corporation.owner
          @corruption_tokens[president][:black] += 2
          @log << "#{corporation.name} uses Private (N) Emisarios de las Sombras to remove the paramilitary token "\
                  "at #{hex_id}. By doing so, its president (#{president.name}) receives "\
                  '2 black corruption tokens from the stock.'
        end

        # Upgrade license: granted to a corporation that built no track and valid only in its next
        # Operating Round.
        def upgrade_license_granted?(corporation)
          @upgrade_licenses.key?(corporation)
        end

        def upgrade_license?(corporation)
          @upgrade_licenses[corporation] == @or_round_number
        end

        def grant_upgrade_license!(corporation)
          @upgrade_licenses[corporation] = @or_round_number + 1
        end

        def consume_upgrade_license!(corporation)
          return false unless upgrade_license?(corporation)

          @upgrade_licenses.delete(corporation)
          true
        end

        def expire_upgrade_license_if_unused!(corporation)
          return unless upgrade_license?(corporation)

          @upgrade_licenses.delete(corporation)
          @log << "#{corporation.name} did not use its Upgrade License within the deadline, "\
                  'which has expired'
        end

        def expire_stale_upgrade_licenses!
          @upgrade_licenses.reject! { |_corporation, valid_on_round| valid_on_round < @or_round_number }
        end

        # Final wealth: cash plus share values (private companies do not count).
        def player_value(player)
          return super unless player.bankrupt

          super - player.companies.sum(&:value)
        end

        # Laguna (E11): the yellow J16 may be upgraded straight to the gray J17.
        def upgrades_to_correct_color?(from, to, selected_company: nil)
          return true if from.name == 'J16' && to.name == 'J17'

          super
        end

        # Final ranking: higher wealth, then fewer black tokens, then fewer white tokens, then seating order.
        def result
          ranked = result_players.each_with_index.sort_by do |p, index|
            tokens = @corruption_tokens.key?(p) ? @corruption_tokens[p] : { white: 0, black: 0 }
            [-player_value(p), tokens[:black], tokens[:white], index]
          end
          ranked.each_with_object({}) { |(p, _), scores| scores[p.id] = player_value(p) }
        end

        # After the private auction the player with the most cash gets priority; ties keep the seating order.
        def reorder_players(order = nil, log_player_order: false)
          return super unless @round.is_a?(Engine::Round::Auction)

          richest = @players.max_by(&:cash)
          tied = @players.select { |p| p.cash == richest.cash } - [richest]
          @players.rotate!(@players.index(richest))

          msg = "#{richest.name} has priority (most cash after the auction)."
          unless tied.empty?
            names = tied.map(&:name)
            names = names.size == 1 ? names.first : "#{names[0..-2].join(', ')} and #{names.last}"
            msg += " Tied with #{names}; the tie was broken by seating order."
          end
          @log << msg
        end

        # A corporation may only buy private companies owned by its president.
        def purchasable_companies(entity = nil)
          companies = super
          return companies unless entity&.corporation?

          companies.select { |company| company.owner == entity.owner }
        end

        def bid_increment
          @optional_rules.include?(:bid_increment_10) ? 10 : 5
        end

        def new_auction_round
          select_game_entities!
          Round::Auction.new(self, [G18Junta::Step::PrivateAuction])
        end
      end
    end
  end
end
