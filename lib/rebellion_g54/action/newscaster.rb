require 'rebellion_g54/action/base'

module RebellionG54; module Action; class Newscaster < Base
  @flavor_name = 'Propaganda'
  @description = 'Pay 1 coin and exchange 3 cards with deck'
  @required_role = :reporter
  @cost = 1

  def resolve(game, token, active_player, join_players, target_players)
    game.communications_add_deck(token, 3)
    game.communications_add_player(token, active_player)
    active_player.influence.times { game.enqueue_communications_decision(token, active_player) }
  end
end; end; end
