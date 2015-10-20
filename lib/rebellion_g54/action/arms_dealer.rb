require 'rebellion_g54/action/base'

require 'rebellion_g54/role'

module RebellionG54; module Action; class ArmsDealer < Base
  @flavor_name = 'Supply'
  @description = 'Gain 4 coins if at least one of two random cards in deck is %s'
  @required_role = :arms_dealer
  @arguments = [{type: :role}.freeze].freeze

  def initialize(target_role)
    @target_role = target_role
    @prepared = false
  end

  def self.effect
    @description % 'target role'
  end

  def prepare(game, token)
    @prepared = true
    @drawn_roles = game.random_deck_roles(token, 2)
    @success = @drawn_roles.include?(@target_role)
  end

  def effect(_ = nil)
    target = Role::to_s(@target_role)
    return self.class.description % target unless @prepared

    drawn_str = @drawn_roles.map { |r| Role::to_s(r) }
    prefix = "Drew #{drawn_str.join(' and ')}"
    if @success
      "#{prefix}, gain 4 coins for finding #{target}"
    else
      "#{prefix}, didn't find a #{target}"
    end
  end

  def resolve(game, token, active_player, join_players, target_players)
    active_player.give_coins(token, 4) if @success
  end
end; end; end
