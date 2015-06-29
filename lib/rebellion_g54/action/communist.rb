require 'rebellion_g54/action/base'

module RebellionG54; module Action; class Communist < Base
  @flavor_name = 'Redistribution'
  @description = 'Take 3 coins from %s and give to %s'
  @required_role = :communist
  @arguments = [
    {type: :player, richest: true, self: true}.freeze,
    {type: :player, poorest: true, self: true, friendly: true}.freeze,
  ].freeze
  @blockable = true

  # Ah, the only two-target action... the strings will need something special.

  def self.effect
    @description % ['the richest', 'the poorest']
  end

  attr_reader :original_targets

  def initialize(richest, poorest)
    @original_targets = [richest, poorest].freeze
  end

  def potential_blockers
    # The poorest player (receiving money) wouldn't want to block...
    [@original_targets.first]
  end

  def effect(target_players: @original_targets)
    if target_players.size == 2
      desc = self.class.description
      rich = target_players[0]
      poor = target_players[1]
    else
      desc = self.class.description.gsub('3', '0')
      rich = @original_targets[0]
      # poor should always be here, but just in case someone messes with us...
      poor = target_players[0] || @original_targets[1]
    end
    "#{desc % [rich, poor]}"
  end

  def resolve(game, token, active_player, join_players, target_players)
    # rich player blocked (so no longer in the target array)
    return if target_players.size < 2

    rich = target_players[0]
    poor = target_players[1]

    coins_taken = rich.take_coins(token, 3)
    poor.give_coins(token, coins_taken)
  end
end; end; end
