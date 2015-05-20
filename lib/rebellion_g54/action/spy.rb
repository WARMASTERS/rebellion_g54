require 'rebellion_g54/action/base'

module RebellionG54; module Action; class Spy < Base
  @flavor_name = 'Intel'
  @description = 'Gain 1 coin and take another non-Spy action'
  @required_role = :spy
  @another_turn = true

  def resolve(game, token, active_player, join_players, target_players)
    active_player.give_coins(token, 1)
  end
end; end; end
