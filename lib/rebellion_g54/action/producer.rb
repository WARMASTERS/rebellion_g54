require 'rebellion_g54/action/base_single_target'

module RebellionG54; module Action; class Producer < BaseSingleTarget
  @flavor_name = 'Propaganda'
  @description = 'Exchange 1 card with deck and 1 card with %s'
  @required_role = :producer
  @blockable = true

  def effect(target_players: @original_targets)
    return 'Exchange 1 card with deck' if target_players.empty?
    super
  end

  def resolve(game, token, active_player, join_players, target_players)
    game.communications_add_deck(token, 1)
    game.communications_add_player(token, active_player)

    # Since enqueue_communications_* unshifts, the order is reversed.
    # First, target player picks card to give.
    # Then player picks card(s) for self.
    # Then player picks card for target.

    target_players.each { |p|
      game.enqueue_communications_decision(token, active_player, p)
    }
    active_player.influence.times { game.enqueue_communications_decision(token, active_player) }
    target_players.each { |p|
      game.enqueue_communications_give_card_decision(token, p, active_player)
    }
  end
end; end; end
