require 'rebellion_g54/action/base_single_target'

module RebellionG54; module Action; class Judge < BaseSingleTarget
  @flavor_name = 'Frame'
  @description = 'Pay 3 coins to %s, who must then lose influence'
  @required_role = :judge
  @cost = 3
  @blockable = true

  def effect(target_players: @original_targets)
    return "Pay 3 coins to #{@original_targets.first}, who blocked losing influence" if target_players.empty?
    super
  end

  def resolve(game, token, active_player, join_players, target_players)
    # Remember... if target blocks, target_players is empty
    # But I still want the original target to get the money.
    @original_targets.each { |p| p.give_coins(token, 3) }
    target_players.each { |p| game.enqueue_lose_influence_decision(token, p, self.class) }
  end
end; end; end
