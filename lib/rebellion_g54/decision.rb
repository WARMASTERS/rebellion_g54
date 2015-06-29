module RebellionG54; class Decision
  attr_reader :turn_number, :description
  def initialize(turn_number, description, choices:, unavailable_choices: {})
    @turn_number = turn_number
    @description = description
    # All choices a player has currently.
    # Hash[Player => Hash[String => Choice]]
    @choices = choices

    # Copy uppercased keys to lowercased keys.
    @choices.each { |player, menu| menu.each_key { |k| menu[k.downcase] = menu[k] if !menu[k.downcase] } }

    # Any choices for which we want to provide an explanation of why it is unavailable.
    # Hash[Player => Hash[String => String]]
    @unavailable_choices = unavailable_choices
  end

  def self.single_player(turn_number, decider, description, choices:, unavailable_choices: {})
    unavail = unavailable_choices.empty? ? {} : {decider => unavailable_choices}
    new(turn_number, description, choices: {decider => choices}, unavailable_choices: unavail)
  end

  def self.single_player_with_costs(turn_number, decider, description, costs_and_choices:)
    affordable = {}
    unaffordable = {}
    costs_and_choices.each { |cost, choices|
      if decider.coins >= cost
        affordable.merge!(choices)
      else
        choices.each_key { |k| unaffordable[k] = "You don't have #{cost} coins" }
      end
    }
    single_player(turn_number, decider, description, choices: affordable, unavailable_choices: unaffordable)
  end

  def valid_players
    @choices.keys
  end

  def choice_names
    @choices.each.map { |player, cs| [player.user, cs.keys] }.to_h
  end

  def choice_explanations(player)
    return [] unless @choices.has_key?(player)
    available = @choices[player].each.map { |label, choice|
      [label, {description: choice.description, args: choice.args, is_action: choice.is_action?, available: true}]
    }.to_h
    return available unless @unavailable_choices.has_key?(player)
    available.merge(@unavailable_choices[player].each.map { |label, why_unavailable|
      # TODO: description should say what would happen if it were available
      [label, {why_unavailable: why_unavailable, available: false}]
    }.to_h)
  end

  def unavailable
    @unavailable_choices.each.map { |player, cs| [player, cs.each.map { |x| x.join(': ') }] }.to_h
  end

  def empty?
    @choices.empty? || @choices.values.all?(&:empty?)
  end

  def can_auto_complete?
    @choices.values.all? { |v| v.empty? || v.size == 1 && !v.values.first.is_action? }
  end

  def auto_complete
    @choices.values.each { |v| v.values.first.call([]) unless v.empty? }
  end

  def clear_player(player)
    @choices.delete(player)
    @unavailable_choices.delete(player)
  end

  # Expected by Game#take_choice to return [Boolean(success), String(error_message)]
  def take_choice(player, choice, args)
    # If there's an explanation for why this choice isn't available, show it.
    if @unavailable_choices[player] && (explanation = @unavailable_choices[player][choice.downcase])
      return [false, explanation]
    end

    return [false, "#{player} has no choices to make"] unless @choices[player]

    if (callback = @choices[player][choice.downcase])
      callback.call(args)
    else
      return [false, "#{choice} is not a valid choice for #{player}"]
    end
  end
end; end

module RebellionG54; class AutoDecision
  attr_reader :description
  def initialize(description, &block)
    @description = description
    @block = block
  end

  def call
    @block.call
  end
end; end
