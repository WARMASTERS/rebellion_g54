require 'rebellion_g54/action/base_single_target'

module RebellionG54; module Action; class ForeignConsular < BaseSingleTarget
  @flavor_name = 'Alliance'
  @description = 'Make alliance with %s, no targeting each other'
  @required_role = :foreign_consular
  @arguments = [player: {friendly: true}.freeze].freeze

  def resolve(game, token, active_player, join_players, target_players)
    game.set_treaty(token, active_player, target_players.first)
  end
end; end; end
