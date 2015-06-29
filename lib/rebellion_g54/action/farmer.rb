require 'rebellion_g54/action/base_single_target'

module RebellionG54; module Action; class Farmer < BaseSingleTarget
  @flavor_name = 'Cooperation'
  @description = 'Gain 3 coins and give 1 coin to %s'
  @required_role = :farmer
  @arguments = [{type: :player, friendly: true}.freeze].freeze

  def resolve(game, token, active_player, join_players, target_players)
    active_player.give_coins(token, 2)
    target_players.each { |p| p.give_coins(token, 1) }
  end
end; end; end
