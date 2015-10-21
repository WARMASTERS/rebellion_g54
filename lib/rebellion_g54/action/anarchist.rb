require 'rebellion_g54/action/base_single_target'

module RebellionG54; module Action; class Anarchist < BaseSingleTarget
  @flavor_name = 'Bomb'
  @description = 'Pay 3 coins, %s receives a bomb'
  @required_role = :anarchist
  @cost = 3
  @action_requires_role = false

  def resolve(game, token, active_player, join_players, target_players)
    game.enqueue_bomb_detonation(token, self.class)
    eligible_players = game.each_player.map { |p| p } - (target_players + [active_player])
    target_players.each { |p| game.enqueue_bomb_decision(token, p, self.class, eligible_players) }
  end
end; end; end
