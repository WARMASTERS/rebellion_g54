require 'rebellion_g54/action/base'

module RebellionG54; module Action; class PlantationOwner < Base
  @flavor_name = 'Harvest'
  @description = 'Gain 1 coin, all Plantation Owners gain coins equal to the number of Plantation Owners'
  @required_role = :plantation_owner
  @joinable = true
  @join_requires_role = true

  def resolve(game, token, active_player, join_players, target_players)
    # join players plus the active player:
    coins_to_give = join_players.size + 1

    # active player gains one extra.
    active_player.give_coins(token, coins_to_give + 1)

    join_players.each { |p| p.give_coins(token, coins_to_give) }
  end
end; end; end
