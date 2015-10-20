require 'rebellion_g54/action/base_single_target'

module RebellionG54; module Action; class Paramilitary < BaseSingleTarget
  @flavor_name = 'Execution'
  @description = 'Pay 3 coins (5 if target has one influence), %s must lose influence'
  @required_role = :paramilitary
  @cost = 3
  @blockable = true

  attr_reader :cost
  attr_reader :conditional_costs

  def initialize(target)
    super(target)

    if target.influence == 2
      @cost = self.class.cost
      @conditional_costs = []
    else
      @cost = self.class.cost + 2
      @conditional_costs = ["2 coins for targeting #{target} with #{target.influence} influence"]
    end
  end

  def resolve(game, token, active_player, join_players, target_players)
    target_players.each { |p| game.enqueue_lose_influence_decision(token, p, self.class) }
  end
end; end; end
