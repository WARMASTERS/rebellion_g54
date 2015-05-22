require 'rebellion_g54/claim'
require 'set'

module RebellionG54; class Turn
  attr_reader :id, :active_player, :action, :action_claim
  attr_reader :state

  def initialize(id, active_player)
    @id = id
    @active_player = active_player
    @state = :action

    @action = nil
    @action_claim = nil

    # Hash[Player(joiner) => Claim]
    @joiners = {}
    @no_claim_joiners = Set.new

    # Hash[Player(blocker) => Claim]
    @blockers = {}
  end

  STATE_ORDER = {
    action: 0,
    join: 1,
    block: 2,
    resolve: 3,
    on_death: 4,
    finished: 5,
  }

  def state=(new_state)
    old_index = STATE_ORDER[@state]
    new_index = STATE_ORDER[new_state]
    raise "Illegal transition from turn #{@id} #{@state} to #{new_state}" if old_index >= new_index
    @state = new_state
  end

  def action=(action)
    raise "Turn #{@id} has an action already" if @action
    @action = action
    @action_claim = Claim.new(@active_player, action.class, :action) if action.class.required_role
  end

  def join(joiner)
    raise "Turn #{@id} has no action, can't join" unless @action
    if @action.class.join_requires_role?
      @joiners[joiner] = Claim.new(joiner, @action.class, :join)
      @joiners[joiner]
    else
      @no_claim_joiners.add(joiner)
      true
    end
  end

  def block(blocker)
    raise "Turn #{@id} has no action, can't block" unless @action
    @blockers[blocker] = Claim.new(blocker, @action.class, :block)
    @blockers[blocker]
  end

  def successful_joins
    @joiners.values.select(&:truthful?).map(&:claimant) + @no_claim_joiners.to_a
  end

  def successful_blocks
    @blockers.values.select(&:truthful?).map(&:claimant)
  end

  def should_resolve?
    @action_claim.nil? || @action_claim.truthful?
  end
end; end
