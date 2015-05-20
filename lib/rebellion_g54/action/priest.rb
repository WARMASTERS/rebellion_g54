require 'rebellion_g54/action/base_target_all'

module RebellionG54; module Action; class Priest < BaseTargetAll
  @flavor_name = 'Charity'
  @description = 'Take 1 coin from %s'
  @required_role = :priest
  @blockable = true

  def resolve(game, token, active_player, join_players, target_players)
    target_players.each { |p|
      coins_taken = p.take_coins(token, 1)
      active_player.give_coins(token, coins_taken)
    }
  end
end; end; end
