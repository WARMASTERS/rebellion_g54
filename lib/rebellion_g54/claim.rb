module RebellionG54; class Claim
  attr_reader :claimant, :action_class, :card, :type, :challenger, :resolved

  # It is expected that:
  # type is one of :action, :join, :block, :on_lose_influence
  # card is non-nil iff type == on_lose_influence
  def initialize(claimant, action_class, type, card: nil)
    @claimant = claimant
    @action_class = action_class
    @card = card
    @type = type
    @challenger = nil
    @resolved = true
    @truthful = true
  end

  # Ascii art state machine?
  #   [resolved, truthful, NIL challenger]
  #                  | challenger=(some_player)
  #                  v
  #      [NOT resolved, truthful will RAISE]
  #       | truthful=(true)     | truthful=(false)
  #       v                     v
  #  [resolved, truthful]   [resolved, NOT truthful]

  def role
    @action_class.required_role
  end

  def challenger=(challenger)
    raise "Claim #{self} already has a challenger" if @challenger
    @challenger = challenger
    @resolved = false
    @truthful = nil
  end

  def truthful
    raise "#truthful on unresolved claim #{self}" unless @resolved
    @truthful
  end

  def truthful=(result)
    raise "Claim #{self} never had a challenger" unless @challenger
    raise "Claim #{self} already resolved" if @resolved
    @resolved = true
    @truthful = result
  end

  def effect
    case @type
    when :action; "perform #{@action_class.flavor_name}"
    when :on_lose_influence; "perform #{@action_class.flavor_name}"
    when :on_death; "perform #{@action_class.flavor_name}"
    when :join; "join #{@action_class.flavor_name}"
    when :block; "block #{@action_class.flavor_name}"
    else raise "Unknown claim type #{@type}"
    end
  end

  alias :resolved? :resolved
  alias :truthful? :truthful
end; end
