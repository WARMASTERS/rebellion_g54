require 'rebellion_g54/action/base'

module RebellionG54; module Action; class FreedomOfPress < Base
  @flavor_name = 'Freedom of Press'
  @description = 'Exchange 1 card with deck'

  def resolve(game, token, active_player, join_players, target_players)
    game.communications_add_deck(token, 1)
    game.communications_add_player(token, active_player)
    active_player.influence.times { game.enqueue_communications_decision(token, active_player) }
  end
end; end; end
