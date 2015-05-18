require 'rebellion_g54/action/base'

module RebellionG54; module Action; class Peacekeeper < Base
  @flavor_name = 'Peacekeeping'
  @description = 'Gain 1 coin and immunity from targetting except by Coup'
  @required_role = :peacekeeper

  def resolve(game, token, active_player, join_players, target_players)
    active_player.give_coins(token, 1)
    game.set_peace(token, active_player)
  end
end; end; end
