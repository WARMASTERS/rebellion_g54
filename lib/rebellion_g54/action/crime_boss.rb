require 'rebellion_g54/action/base_single_target'

module RebellionG54; module Action; class CrimeBoss < BaseSingleTarget
  @flavor_name = 'Extortion'
  @description = 'Pay 5 coins, %s must pay 2 coins or lose influence'
  @required_role = :crime_boss
  @cost = 5
  @blockable = false

  def resolve(game, token, active_player, join_players, target_players)
    target_players.each { |p|
      game.enqueue_lose_influence_decision(
        token, p, extort_cost: 2, extort_player: active_player
      )
    }
  end
end; end; end
