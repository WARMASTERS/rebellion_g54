require 'rebellion_g54/action/base'

module RebellionG54; module Action; class Income < Base
  @flavor_name = 'Income'
  @description = 'Gain 1 coin'

  def resolve(game, token, active_player, join_players, target_players)
    active_player.give_coins(token, 1)
  end
end; end; end
