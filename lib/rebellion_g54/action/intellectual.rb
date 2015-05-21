require 'rebellion_g54/action/base'

module RebellionG54; module Action; class Intellectual < Base
  @flavor_name = 'Memoirs'
  @description = 'When losing influence, gain 5 coins'
  @required_role = :intellectual
  @timing = :on_lose_influence
  @responds_to_coup = true

  def resolve(game, token, active_player, join_players, target_players)
    active_player.give_coins(token, 5)
  end
end; end; end
