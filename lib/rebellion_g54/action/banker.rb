require 'rebellion_g54/action/base'

module RebellionG54; module Action; class Banker < Base
  @flavor_name = 'Profit'
  @description = 'Gain 3 coins'
  @required_role = :banker

  def resolve(game, token, active_player, join_players, target_players)
    active_player.give_coins(token, 3)
  end
end; end; end
