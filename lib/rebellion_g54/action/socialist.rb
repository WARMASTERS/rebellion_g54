require 'rebellion_g54/action/base_target_all'

module RebellionG54; module Action; class Socialist < BaseTargetAll
  @flavor_name = 'Redistribution'
  @description = 'Take 1 coin or 1 card from %s, redistribute cards randomly'
  @required_role = :socialist

  def resolve(game, token, active_player, join_players, target_players)
    # Since enqueue_communications_* unshifts, the order is reversed.
    # First, target players picks card or coin to give.
    # Then player picks card to contribute to the pool.
    # Then player picks card to keep.

    game.enqueue_communications_random_resolution(token, active_player)
    # Rikki has confirmed that you DO get to see who gave which card.
    game.enqueue_communications_decision(token, active_player)
    game.enqueue_communications_give_own_card_decision(token, active_player)
    target_players.reverse_each { |p|
      game.enqueue_communications_give_card_decision(token, p, active_player, coin: 1)
    }
  end
end; end; end
