require 'rebellion_g54/action/base'

module RebellionG54; module Action; class Missionary < Base
  @flavor_name = 'Sacrifice'
  @description = 'When losing influence, gain another influence card'
  @required_role = :missionary
  @timing = :on_lose_influence
  @responds_to_coup = false

  def resolve(game, token, active_player, join_players, target_players)
    game.give_new_card_from_deck(token, active_player)
  end
end; end; end
