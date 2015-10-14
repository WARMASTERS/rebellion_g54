module RebellionG54; class Decision
  attr_reader :turn_number, :description
  def initialize(turn_number, description, choices:)
    @turn_number = turn_number
    @description = description

    # All choices a player has currently.
    # Hash[Player => Hash[String => Choice]]
    @all_choices = choices

    @unavailable_choices = choices.map { |player, menu|
      [player, menu.reject { |_, choice| choice.available? }]
    }.to_h
    @unavailable_choices.select! { |_, cs| !cs.empty? }

    @available_choices = choices.map { |player, menu|
      [player, menu.select { |_, choice| choice.available? }]
    }.to_h

    # Copy uppercased keys to lowercased keys.
    @available_choices.each { |player, menu| menu.each_key { |k| menu[k.downcase] = menu[k] if !menu[k.downcase] } }
  end

  def self.single_player(turn_number, decider, description, choices:)
    new(turn_number, description, choices: {decider => choices})
  end

  def self.single_player_with_costs(turn_number, decider, description, costs_and_choices:)
    all = costs_and_choices.each_with_object({}) { |(cost, choices), all_choices|
      all_choices.merge!(choices)
      choices.each_value { |v| v.unavailable!("You don't have #{cost} coins") } if decider.coins < cost
    }
    single_player(turn_number, decider, description, choices: all)
  end

  def valid_players
    @available_choices.keys
  end

  def choice_names
    @available_choices.each.map { |player, cs| [player.user, cs.keys] }.to_h
  end

  def choice_explanations(player)
    return [] unless @all_choices.has_key?(player)
    @all_choices[player].each.map { |label, choice|
      info = {
        description: choice.description,
        args: choice.args,
        is_action: choice.is_action?,
        available: choice.available?,
      }
      info.merge!(why_unavailable: choice.why_unavailable) unless choice.available?
      [label, info]
    }.to_h
  end

  def unavailable
    @unavailable_choices.map { |player, cs|
      [player, cs.map { |label, choice| "#{label}: #{choice.description} (#{choice.why_unavailable})" }]
    }.to_h
  end

  def empty?
    @available_choices.empty? || @available_choices.values.all?(&:empty?)
  end

  def can_auto_complete?
    @available_choices.values.all? { |v| v.empty? || v.size == 1 && !v.values.first.is_action? }
  end

  def auto_complete
    @available_choices.values.each { |v| v.values.first.call([]) unless v.empty? }
  end

  def clear_player(player)
    @all_choices.delete(player)
    @available_choices.delete(player)
    @unavailable_choices.delete(player)
  end

  # Expected by Game#take_choice to return [Boolean(success), String(error_message)]
  def take_choice(player, choice, args)
    return [false, "#{player} has no choices to make"] unless @all_choices[player]

    # If there's an explanation for why this choice isn't available, show it.
    if (choice = @all_choices[player][choice.downcase])
      return [false, choice.why_unavailable] unless choice.available?
      choice.call(args)
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
