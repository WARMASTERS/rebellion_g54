require 'rebellion_g54/action/base_single_target'

module RebellionG54; module Action; class Coup < BaseSingleTarget
  @flavor_name = 'Coup'
  @description = 'Pay 7 coins, %s must lose influence'
  @cost = 7

  def resolve(game, token, active_player, join_players, target_players)
    target_players.each { |p| game.enqueue_lose_influence_decision(token, p, self.class) }
  end
end; end; end
