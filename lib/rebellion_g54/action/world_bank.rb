require 'rebellion_g54/action/base'
require 'rebellion_g54/action/income'

module RebellionG54; module Action; class WorldBank < Base
  @flavor_name = 'Banking'
  @description = 'Take all coins from the Bank'
  @required_role = :world_bank

  class State
    attr_reader :bank

    def initialize
      @bank = 0
    end

    def name_and_effect
      "#{flavor_name} (#{effect})"
    end

    def effect
      "Take all #{@bank} coin#{'s' if @bank != 1} from the Bank"
    end

    def action_performed(action_class)
      @bank += 1 if action_class == Income
    end

    def take_bank
      bank = @bank
      @bank = 0
      bank
    end

    def new(*args)
      WorldBank.new(self, *args)
    end

    def method_missing(m, *args)
      WorldBank.send(m, *args)
    end
  end

  @per_game_state = State

  def initialize(state, *args)
    super(*args)
    @state = state
    @taken = nil
  end

  def effect(_ = nil)
    # If we took already, used saved @taken value. Else, read from bank.
    taken = @taken || @state.bank
    "Take all #{taken} coin#{'s' if taken != 1} from the Bank"
  end

  def resolve(game, token, active_player, join_players, target_players)
    @taken = @state.take_bank
    active_player.give_coins(token, @taken)
  end
end; end; end
