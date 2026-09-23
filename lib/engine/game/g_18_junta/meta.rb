# frozen_string_literal: true

require_relative '../meta'

module Engine
  module Game
    module G18Junta
      module Meta
        include Game::Meta

        DEV_STAGE = :prealpha
        PROTOTYPE = true

        GAME_SUBTITLE = 'version 3.0'
        GAME_DESIGNER = 'Leandro Pires'
        GAME_LOCATION = 'Junta (fictional Central America)'
        GAME_RULES_URL = 'https://drive.google.com/file/d/1_0XlLK2M5W1jqus6HTSdZmkBEi52vdG2/view?usp=sharing'

        PLAYER_RANGE = [2, 4].freeze
      end
    end
  end
end
