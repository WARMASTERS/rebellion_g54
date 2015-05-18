require 'rebellion_g54/action/base_single_target'

module RebellionG54; module Action; class Lawyer < BaseSingleTarget
  @flavor_name = 'Probate'
  @description = 'Claim the coins of the deceased %s'
  @required_role = :lawyer
  @timing = :on_death

  def resolve(game, token, active_player, join_players, target_players)
    target_players.each { |p|
      coins_to_give = p.coins / join_players.size
      join_players.each { |j|
        p.take_coins(token, coins_to_give)
        j.give_coins(token, coins_to_give)
      }
    }
  end
end; end; end
