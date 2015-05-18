require 'rebellion_g54/action/base'

module RebellionG54; module Action; class BaseTargetAll < Base
  attr_reader :original_targets

  @targets_all = true

  def initialize(*targets)
    @original_targets = targets
  end

  def self.effect
    @description % 'everyone'
  end

  def effect(target_players: @original_targets)
    targets = target_players.empty? ? 'nobody' : target_players.map(&:to_s).join(', ')
    "#{self.class.description % targets}"
  end
end; end; end
