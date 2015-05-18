require 'rebellion_g54/action/base_single_target'

module RebellionG54; module Action; class Politician < BaseSingleTarget
  @flavor_name = 'Bribery'
  @description = 'Take 2 coins from %s'
  @required_role = :politician
  @blockable = true

  def resolve(game, token, active_player, join_players, target_players)
    target_players.each { |p|
      coins_taken = p.take_coins(token, 2)
      active_player.give_coins(token, coins_taken)
    }
  end
end; end; end
