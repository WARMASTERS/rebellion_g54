require 'rebellion_g54/action/base'

module RebellionG54; module Action; class Writer < Base
  @flavor_name = 'Propaganda'
  @description = 'Exchange 1 card with deck, more for 1 coin per card'
  @required_role = :writer

  def resolve(game, token, active_player, join_players, target_players)
    game.communications_add_deck(token, 1)
    game.communications_add_player(token, active_player)
    active_player.influence.times { game.enqueue_communications_decision(token, active_player) }
    game.enqueue_communications_redraw_decision(token, active_player, 1)
  end
end; end; end
