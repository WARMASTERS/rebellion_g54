require 'rebellion_g54/action/base_single_target'

module RebellionG54; module Action; class Mercenary < BaseSingleTarget
  @flavor_name = 'Disappear'
  @description = 'Pay 3 coins, %s must lose influence at end of next turn'
  @required_role = :mercenary
  @cost = 3
  @blockable = true

  def resolve(game, token, active_player, join_players, target_players)
    target_players.each { |p| game.set_disappear(token, p, self) }
  end
end; end; end
