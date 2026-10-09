# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18Junta
      module Step
        # 18Junta Regras 2.1, 4.2 / tabuleiro: ao construir num hexágono de
        # paramilitar ainda não reclamado, a companhia deve pagar $30 e
        # escolher que lado apoiar (civil/azul ou militar/verde), o que move
        # a trilha política — a menos que possua a privada (C), que permite
        # descartar a ficha de graça, sem custo e sem mover a trilha.
        class ParamilitarChoice < Engine::Step::Base
          ACTIONS = %w[choose].freeze

          # Round::Base#description (chamado pela view a cada render, pra
          # mostrar o cabeçalho da rodada) faz active_step.description --
          # e Step::Base#description por padrão só dá "raise
          # NotImplementedError". Sem isso sobrescrito aqui, o jogo
          # quebrava (tela inteira) no exato instante em que este passo
          # vira o bloqueador, ou seja, assim que um trilho é construído
          # num hexágono de paramilitar -- por fora parecia que "o jogo
          # trava ao colocar um tile em locais militares".
          def description
            'Paramilitary Token'
          end

          def actions(entity)
            return [] unless entity == current_entity
            return [] unless @game.pending_paramilitar_choice_for?(entity)

            ACTIONS
          end

          def blocks?
            @game.pending_paramilitar_choice_for?(current_entity)
          end

          def choice_name
            hex = @game.pending_paramilitar_hex
            "A paramilitary group was identified at #{hex&.name}: which side will the company support now?"
          end

           def choices
            choice_hash = {
              'civil' => 'Support the Civilian side',
              'militar' => 'Support the Military side',
            }
            if @game.discard_paramilitar_free?(current_entity)
              choice_hash['descartar'] = 'Discard the token without choosing a side [Private (C)]'
            end
            choice_hash
          end

          def process_choose(action)
            @game.resolve_paramilitar_choice!(action.entity, action.choice)
            # rev. 2.8: o passo fica antes do Track e pode ser necessário
            # duas vezes no mesmo turno (trilho da (F) e trilho normal em
            # dois hexágonos de paramilitar); sem pendência ele não bloqueia
            # nem oferece ações, então não precisa passar.
            pass! unless @game.rev_2_8?
          end
        end
      end
    end
  end
end
