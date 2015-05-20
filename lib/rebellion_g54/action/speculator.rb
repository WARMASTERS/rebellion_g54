require 'rebellion_g54/action/base'

module RebellionG54; module Action; class Speculator < Base
  @flavor_name = 'Gamble'
  @description = 'Double your coins (max gain 5), give all coins to challenger if lying'
  @required_role = :speculator

  def self.found_lying(token, claimant, challenger)
    coins_taken = claimant.take_coins(token, claimant.coins)
    challenger.give_coins(token, coins_taken)
  end

  def resolve(game, token, active_player, join_players, target_players)
    gain = [active_player.coins, 5].min
    active_player.give_coins(token, gain)
  end
end; end; end
