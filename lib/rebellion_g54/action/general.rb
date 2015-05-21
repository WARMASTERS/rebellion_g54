require 'rebellion_g54/action/base_target_all'

module RebellionG54; module Action; class General < BaseTargetAll
  @flavor_name = 'Purge'
  @description = 'Pay 5 coins, %s must lose influence'
  @required_role = :general
  @cost = 5
  @blockable = true

  def resolve(game, token, active_player, join_players, target_players)
    # Hmm implementation detail? I know enqueue does unshift, so I'll reverse.
    # That way the target that was first will decide first
    target_players.reverse.each { |p| game.enqueue_lose_influence_decision(token, p, self.class) }
  end
end; end; end
