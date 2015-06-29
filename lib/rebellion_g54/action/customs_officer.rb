require 'rebellion_g54/action/base'

require 'rebellion_g54/role'

module RebellionG54; module Action; class CustomsOfficer < Base
  @flavor_name = 'Tax'
  @description = 'Place a 1-coin tax on any claims of %s'
  @required_role = :customs_officer
  @arguments = [{type: :role}.freeze].freeze

  def initialize(target_role)
    @target_role = target_role
  end

  def self.effect
    @description % 'target role'
  end

  def effect(_ = nil)
    self.class.description % Role::to_s(@target_role)
  end

  def resolve(game, token, active_player, join_players, target_players)
    game.set_tax(token, active_player, @target_role)
  end
end; end; end
