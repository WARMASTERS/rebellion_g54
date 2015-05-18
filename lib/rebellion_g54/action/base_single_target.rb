require 'rebellion_g54/action/base'

module RebellionG54; module Action; class BaseSingleTarget < Base
  attr_reader :original_targets

  @arguments = [:player].freeze

  def self.effect
    @description % 'target'
  end

  def initialize(target_player)
    @original_targets = [target_player]
  end

  def effect(target_players: @original_targets)
    targets = target_players.empty? ? 'nobody' : target_players.map(&:to_s).join(', ')
    "#{self.class.description % targets}"
  end
end; end; end
