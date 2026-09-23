# frozen_string_literal: true

module Engine
  module Game
    module G18Junta
      module Map2P
        # Mapa reduzido para partidas de 2 jogadores (18Junta Regras 2.1,
        # "Partidas em 2 Jogadores"). Copia independente de HEXES (map.rb),
        # nao derivada automaticamente -- editar aqui nao afeta o mapa de
        # 3-4 jogadores, e vice-versa.
       HEXES_2P = {
          orange: {
            ['A2'] => '',
          },

          white: {
            %w[D8 D14 E5] => '', # terrenos livres
            %w[B14 C11 E7 G3 G13 I9 J4 L8] => 'icon=image:18_junta/militia,large:2', # terrenos livres com paramilitar
            %w[C15 G5 H8 K13] => 'town=revenue:0,style:hidden;label= ;icon=image:18_junta/fazenda4;'\
                                     'upgrade=cost:25,terrain:farm', # terrenos livres com fazenda
            %w[C13 D10 E13 F4 F12 I5 I11 J12 K5 K9] => 'city=revenue:0', # cidades
            %w[C9 F8 H12] => 'town=revenue:0', # vilas
            %w[F6 G9 H4 H10 I7 L10] => 'upgrade=cost:50,terrain:mountain', # montanhas
            ['K11'] => 'upgrade=cost:50,terrain:mountain;icon=image:18_junta/militia,large:2', # montanha com paramilitar
            %w[B10 E9 G11 H6 J6 J10] => 'town=revenue:0,style:hidden;label= ;icon=image:18_junta/fazenda4,loc:15;'\
                                          'upgrade=cost:75,terrain:mountain|farm', # montanhas com fazendas
            %w[D12 K7] => 'town=revenue:0;upgrade=cost:50,terrain:mountain', # vilas em montanha
            ['J8'] => 'city=revenue:0;upgrade=cost:50,terrain:mountain', # cidade-sede da Montañera, em montanha
            ['E11'] => 'label=L;stripes=color:blue;upgrade=cost:100,terrain:river', # Laguna
          },
          green: {
            ['G7'] => 'city=revenue:30,slots:2;path=a:1,b:_0;path=a:2,b:_0;path=a:4,b:_0;path=a:5,b:_0;label=V',
            ['L6'] => 'city=revenue:30,slots:2;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;label=M',
          },
          brown: {
            ['F10'] => 'city=revenue:yellow_40|brown_60,slots:2;path=a:1,b:_0;path=a:5,b:_0;label=S',
          },
          gray: {
            ['B12'] => 'path=a:1,b:3;path=a:3,b:6',
          },
          red: {
            ['A13'] => 'offboard=revenue:yellow_40|brown_60;path=a:4,b:_0;path=a:5,b:_0;future_label=label:80,color:red',
            ['D6'] => 'offboard=revenue:yellow_30|brown_60;path=a:0,b:_0;path=a:4,b:_0;path=a:5,b:_0;future_label=label:50,color:red',
            ['L12'] => 'offboard=revenue:yellow_30|brown_50;path=a:1,b:_0;path=a:2,b:_0;path=a:3,b:_0;future_label=label:40,color:red',
            ['I3'] => 'offboard=revenue:yellow_30|brown_60;path=a:0,b:_0;path=a:1,b:_0;path=a:5,b:_0;future_label=label:50,color:red',
          },
        }.freeze









      end
    end
  end
end
