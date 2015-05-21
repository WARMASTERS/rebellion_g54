require 'rebellion_g54/role'

module RebellionG54; module Action; module ClassLevelInheritableAttributes
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def inheritable_attributes(*args)
      @inheritable_attributes ||= [:inheritable_attributes]
      @inheritable_attributes += args
      class_eval("class << self; attr_reader #{args.map { |a| ":#{a}" }.join(', ')}; end")
      @inheritable_attributes
    end

    def inherited(subclass)
      @inheritable_attributes.each do |inheritable_attribute|
        instance_var = "@#{inheritable_attribute}"
        subclass.instance_variable_set(instance_var, instance_variable_get(instance_var))
      end
    end
  end
end; end; end

module RebellionG54; module Action; class Base
  include ClassLevelInheritableAttributes
  inheritable_attributes :flavor_name, :description, :required_role
  inheritable_attributes :timing, :arguments, :cost, :targets_all
  inheritable_attributes :joinable, :join_cost, :join_requires_role, :blockable
  inheritable_attributes :another_turn
  inheritable_attributes :responds_to_coup

  class << self
    alias :joinable? :joinable
    alias :join_requires_role? :join_requires_role
    alias :blockable? :blockable
    alias :another_turn? :another_turn
    alias :responds_to_coup? :responds_to_coup
  end

  @flavor_name = 'UNNAMED'
  @description = 'Description of this action!'
  @required_role = nil
  @timing = :main_action # Expected values are :main_action, :on_death, and :on_lose_influence
  @arguments = [].freeze
  @cost = 0
  @targets_all = false
  @joinable = false
  @join_cost = 0
  @join_requires_role = false
  @blockable = false
  @another_turn = false
  @responds_to_coup = false # Only important for :on_lose_influence

  # This is used to build Decisions.
  # A Player indicates "my_class_name" to use the MyClassName action.
  def self.slug
    @cached_slug ||= to_s.split('::').last.gsub(/(.)([A-Z])/) { |_| $1 + '_' + $2 }.downcase
  end

  def self.name_and_effect
    "#{@flavor_name} (#{effect})"
  end

  # This is meant for when targets are unknown.
  def self.effect
    @description
  end

  def player_joined(player)
    # NOTE that this will only be called if join_requires_role is false.
    # Otherwise, we won't know who has actually joined until challenges resolve.
  end

  def original_targets
    []
  end

  def potential_blockers
    original_targets
  end

  # This is meant for when targets are known.
  def effect(target_players: nil)
    self.class.description
  end

  def to_s
    requirement = self.class.required_role ? " (requires #{Role.to_s(self.class.required_role)})" : ''
    "#{self.class.flavor_name}#{requirement}: #{effect}"
  end

  def self.found_lying(token, claimant, challenger)
  end

  # At this point, challenges have resolved.
  # If this method is called, the active player was not challenged, or was truthful on a challenge.
  # All players in join_players have passed their challenges.
  # All blocking players who passed their challenges have been removed from target_players
  def resolve(game, token, active_player, join_players, target_players)
  end
end; end; end
