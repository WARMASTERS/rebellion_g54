require 'rebellion_g54/action/base_single_target'

module RebellionG54; module Action; class Guerrilla < BaseSingleTarget
  @flavor_name = 'Execution'
  @description = 'Pay 4 coins, %s must lose influence'
  @required_role = :guerrilla
  @cost = 4
  @blockable = true

  def resolve(game, token, active_player, join_players, target_players)
    target_players.each { |p| game.enqueue_lose_influence_decision(token, p, self.class) }
  end
end; end; end
