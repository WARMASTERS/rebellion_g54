require 'rebellion_g54/action/base_single_target'

module RebellionG54; module Action; class Protestor < BaseSingleTarget
  @flavor_name = 'Riot'
  @description = 'Pay 2 coins. If someone pays 3 coins and joins, %s must lose influence'
  @required_role = :protestor
  @cost = 2
  @joinable = true
  @join_cost = 3
  @blockable = true

  def player_joined(player)
    @joined_player = player
  end

  def potential_blockers
    # Only needs a block if someone joined.
    @joined_player ? original_targets : []
  end

  def resolve(game, token, active_player, join_players, target_players)
    return if join_players.empty?
    target_players.each { |p| game.enqueue_lose_influence_decision(token, p, self.class) }
  end
end; end; end
