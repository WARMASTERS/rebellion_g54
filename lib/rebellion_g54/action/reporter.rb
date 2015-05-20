require 'rebellion_g54/action/base'

module RebellionG54; module Action; class Reporter < Base
  @flavor_name = 'Propaganda'
  @description = 'Gain 1 coin and exchange 1 card with deck'
  @required_role = :reporter

  def resolve(game, token, active_player, join_players, target_players)
    active_player.give_coins(token, 1)
    game.communications_add_deck(token, 1)
    game.communications_add_player(token, active_player)
    active_player.influence.times { game.enqueue_communications_decision(token, active_player) }
  end
end; end; end
