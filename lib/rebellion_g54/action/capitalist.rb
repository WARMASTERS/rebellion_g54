require 'rebellion_g54/action/base'

module RebellionG54; module Action; class Capitalist < Base
  @flavor_name = 'Dividends'
  @description = 'Gain 4 coins, pay 1 coin to each other Capitalist'
  @required_role = :capitalist
  @joinable = true
  @join_requires_role = true

  def resolve(game, token, active_player, join_players, target_players)
    active_player.give_coins(token, 4)
    coins_left = active_player.take_coins(token, join_players.size)

    # It's possible that the last player doesn't get a coin... sad.
    join_players.each { |p|
      break if coins_left == 0
      p.give_coins(token, 1)
      coins_left -= 1
    }
  end
end; end; end
