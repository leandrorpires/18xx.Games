# frozen_string_literal: true

require_relative '../../../step/base'
require_relative '../../../step/passable_auction'

module Engine
  module Game
    module G18Junta
      module Step
        # Leilão inicial das empresas privadas (18Junta Regras 2.1, 6.1):
        # o jogador da vez escolhe uma privada disponível pra dar lance
        # (mínimo o valor impresso, incrementos de $5) ou passa a escolha
        # pro próximo jogador. Uma vez escolhida, os demais jogadores
        # (em sentido horário) dão lances maiores ou passam, até sobrar um
        # interessado, que paga seu lance e leva a carta — e passa a
        # escolher a próxima privada a ser leiloada.
        #
        # Se todos os jogadores passarem a escolha sem leiloar nada, o
        # jogador da vez pode abrir um leilão forçado por até metade do
        # valor da privada (arredondado pra cima). Se ele também recusar,
        # as privadas remanescentes saem do jogo.
        class PrivateAuction < Engine::Step::Base
          include Engine::Step::PassableAuction

          ACTIONS = %w[bid pass].freeze

          attr_reader :companies

          def description
            'Private Company Auction'
          end

          def available
            @companies
          end

          def may_bid?(company)
            return false unless @companies.include?(company)

            super
          end

          # Sem compra direta por preço fixo aqui -- só lance competitivo
          # (leilão inglês simples, Regras 2.1, 6.1). A view compartilhada
          # (assets/app/view/game/round/auction.rb#render_company_actions)
          # chama isso incondicionalmente (sem respond_to?) assim que o
          # jogador seleciona uma privada; sem esse método definido, o clique
          # derrubava o render inteiro com NoMethodError -- por fora parecia
          # que "clicar na privada não fazia nada".
          def may_purchase?(_company)
            false
          end

          def active_entities
            return super unless auctioning

            winning_bid = highest_bid(auctioning)
            return [@active_bidders[0]] unless winning_bid

            next_index = (@active_bidders.index(winning_bid.entity) + 1) % @active_bidders.size
            [@active_bidders[next_index]]
          end

          def min_increment
            5
          end

          def min_bid(company)
            return unless company

            return forced_min_bid(company) if !@bids[company] || @bids[company].empty?

            highest_bid(company).price + min_increment
          end

          # rev. 2.8, 2.1: no leilão com desconto, o lance de abertura é de
          # pelo menos metade do valor (ver forced_min_bid), sem teto.
          def max_bid(player, _company)
            player.cash
          end

          def actions(entity)
            return [] if @companies.empty?
            return [] unless entity == current_entity

            ACTIONS
          end

          def setup
            setup_auction
            @companies = @game.companies.reject(&:closed?).dup
            @consecutive_choosing_passes = 0
            @forced_round = false
          end

          def process_pass(action)
            entity = action.entity

            if auctioning
              pass_auction(entity)
              resolve_bids
            else
              @log << "#{entity.name} passes the auction choice"

              # Uma volta completa da mesa sem ninguém iniciar um leilão
              # normal: dá a cada jogador, em ordem de turno A PARTIR de
              # quem começou esta volta, a chance de abrir um leilão com
              # desconto (até metade do valor). Uma volta INTEIRA sem
              # ninguém topar -- inclusive já em modo "leilão com
              # desconto" -- é que tira as privadas remanescentes do
              # jogo. (Antes disso, um único jogador recusando a oferta
              # com desconto já zerava as privadas sem dar chance aos
              # demais -- bug reportado pelo designer.)
              @consecutive_choosing_passes += 1

              if @consecutive_choosing_passes < entities.size
                @round.next_entity_index!
              elsif @forced_round
                @log << 'No player wanted to start another auction — the remaining Private Companies are removed from the game'
                @companies.each { |c| @game.remove_company(c) }
                @companies = []
              else
                @forced_round = true
                @consecutive_choosing_passes = 0
                @round.next_entity_index!
                @log << "#{entities[entity_index].name} may open an auction for at least half the value of a "\
                        'remaining Private Company'
              end
            end
          end

          def process_bid(action)
            # rev. 2.8 (decisão do designer): todos os lances são múltiplos de $5.
            if @game.rev_2_8? && (action.price % 5).nonzero?
              raise GameError, 'Bids must be a multiple of $5'
            end

            action.entity.unpass!

            if auctioning
              add_bid(action)
            else
              @consecutive_choosing_passes = 0
              was_forced = @forced_round
              selection_bid(action)
              @forced_round = false
              @log << "#{action.entity.name} uses the discount auction (half value)" if was_forced
            end
          end

          private

          # Leilão com desconto: metade do valor, arredondada para cima. Na
          # rev. 2.8 o arredondamento vai até o próximo múltiplo de $5
          # ($35 -> $20, $45 -> $25); jogos anteriores mantêm ($35 -> $18).
          def forced_min_bid(company)
            return company.min_bid unless @forced_round
            return (company.min_bid / 2.0).ceil unless @game.rev_2_8?

            (company.min_bid / 10.0).ceil * 5
          end

          def add_bid(bid)
            super
            @log << "#{bid.entity.name} bids #{@game.format_currency(bid.price)} for #{bid.company.name}"
          end



             
          # Sugestão do Claude para Leandro para resolver erro do próximo jogador a puxar um leilão 19-09-2026
              def win_bid(winner, company)
              player = winner.entity
              price = winner.price

              company.owner = player
              player.companies << company
              player.spend(price, @game.bank) if price.positive?
              @log << "#{player.name} wins the auction for #{company.name} with a bid of #{@game.format_currency(price)}"

              @companies.delete(company)
              winner_index = entities.index(player) || 0
              @round.entity_index = (winner_index + 1) % entities.size
            end

          # def win_bid(winner, company)
          #   player = winner.entity
          #   price = winner.price

          #   company.owner = player
          #   player.companies << company
          #   player.spend(price, @game.bank) if price.positive?
          #   @log << "#{player.name} vence o leilão de #{company.name} por #{@game.format_currency(price)}"

          #   @companies.delete(company)
          #   @round.entity_index = entities.index(player) || 0
          # end

          
        end
      end
    end
  end
end
