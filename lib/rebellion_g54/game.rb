require 'rebellion_g54/action/all'
require 'rebellion_g54/card'
require 'rebellion_g54/choice'
require 'rebellion_g54/claim'
require 'rebellion_g54/decision'
require 'rebellion_g54/player'
require 'rebellion_g54/role'
require 'rebellion_g54/turn'

module RebellionG54; class Game
  GAME_NAME = 'Rebellion G54'
  MIN_PLAYERS = 2
  MAX_PLAYERS = 6
  ROLES_PER_GAME = 5

  STARTING_INFLUENCE = 2
  STARTING_COINS = 2

  attr_reader :id, :channel_name, :started, :roles
  attr_accessor :output_streams

  alias :started? :started

  class << self
    attr_accessor :games_created
  end

  @games_created = 0

  class Token; end

  def initialize(channel_name)
    self.class.games_created += 1
    @id = self.class.games_created

    @channel_name = channel_name
    @players = []
    # dead players are no longer in @players, preventing them from taking actions
    @dead_players = []
    @started = false
    # roles is frozen once game begins
    @roles = [:director, :banker, :guerrilla, :politician, :peacekeeper]

    @taxed_role = nil
    @taxing_player = nil

    @treaty_players = [].freeze
    @peace_player = nil

    # Hash[Action => Hash[Player(dead_player) => Array[Player(claimant)]]]
    @death_claims = {}

    # Set on game start (actions is frozen, deck changes)
    @actions = []
    @deck = []

    @turns = []

    # List of no-argument functions to call to get more decisions.
    # If it's empty, move on to the next phase.
    @upcoming_decisions = []
    @current_decision = nil

    @communications_available = []
    # Hash[Card => [Player?(Source, nil if deck), Player?(Target, nil if deck)]
    @communications_assignments = {}

    @output_streams = []

    @main_token = Token.new
    @action_token = Token.new
  end

  def output(message)
    @output_streams.each { |o| o.puts(message) }
  end

  #----------------------------------------------
  # Required methods for player management
  #----------------------------------------------

  def size
    @players.size
  end

  def users
    @players.map(&:user)
  end

  def has_player?(user)
    @players.any? { |p| p.user == user }
  end

  def add_player(user)
    raise "Cannot add #{user} to #{@channel_name}: game in progress" if @started
    return false if has_player?(user)
    new_player = Player.new(user, @main_token, @action_token)
    @players << new_player
    true
  end

  def remove_player(user)
    raise "Cannot remove #{user} from #{@channel_name}: game in progress" if @started
    player = find_player(user)
    return false unless player
    @players.delete(player)
    true
  end

  def replace_player(replaced, replacing)
    player = find_player(replaced)
    return false unless player
    player.user = replacing
    true
  end

  #----------------------------------------------
  # Please use externally sparingly.
  #----------------------------------------------

  def each_player
    @players.each
  end

  def each_dead_player
    @dead_players.each
  end

  def find_player(user)
    @players.find { |p| p.user == user }
  end

  def find_dead_player(user)
    @dead_players.find { |p| p.user == user }
  end

  #----------------------------------------------
  # Game state getters
  #----------------------------------------------

  def current_user
    current_player.user
  end

  def user_coins(user)
    p = find_player(user)
    p && p.coins
  end

  def user_influence(user)
    p = find_player(user)
    p && p.influence
  end

  def turn_number
    @turns.size
  end

  def decision_description
    @current_decision.description
  end

  def choice_names
    @current_decision.choice_names
  end

  def choice_explanations(user)
    player = find_player(user)
    return [] unless player
    @current_decision.choice_explanations(player)
  end

  def winner
    return nil if @players.size > 1
    @players.first.user
  end

  #----------------------------------------------
  # Setters
  #----------------------------------------------

  def roles=(new_roles)
    raise "Cannot change roles of game #{@channel_name}: game in progress" if @started
    @roles = new_roles
  end

  #----------------------------------------------
  # Game state changers
  #----------------------------------------------

  def start_game(strict_roles: true, shuffle_players: true, rigged_players: nil)
    raise "Game #{@channel_name} already started" if @started

    if strict_roles
      return [false, "Need #{ROLES_PER_GAME} roles instead of #{@roles.size}"] if @roles.size != ROLES_PER_GAME
      invalid_roles = @roles.reject { |r| Role::ALL.has_key?(r) }
      return [false, "Roles #{invalid_roles} are invalid"] unless invalid_roles.empty?
    end

    @started = true
    @roles.freeze

    @players.shuffle! if shuffle_players

    @deck = []
    card_id = 1
    @actions << Action::Income
    @actions << Action::Coup
    @roles.each do |role|
      @actions << Action.const_get(Role::to_class_name(role))
      3.times.each do
        @deck << Card.new(card_id, role)
        card_id += 1
      end
    end
    @actions.freeze

    @death_claims = @actions.select { |a| a.timing == :on_death }.map { |a| [a, {}] }.to_h

    @deck.shuffle!

    if rigged_players
      @players.zip(rigged_players).each { |player, rigged|
        cards_to_give = []
        (rigged[:roles] || []).each { |role|
          card = @deck.find { |d| d.role == role }
          if card
            @deck.delete(card)
            cards_to_give << card
          end
        }
        cards_to_give << @deck.shift until cards_to_give.size >= STARTING_INFLUENCE
        player.receive_cards(@main_token, cards_to_give)
        player.give_coins(@action_token, rigged[:coins] || STARTING_COINS)
      }
    else
      @players.each do |player|
        player.receive_cards(@main_token, @deck.shift(STARTING_INFLUENCE))
        player.give_coins(@action_token, STARTING_COINS)
      end
    end

    next_turn

    [true, '']
  end

  def take_choice(user, choice, args = '')
    player = find_player(user)
    return [false, "#{user} is not in the game"] unless player
    @current_decision.take_choice(player, choice, args.split)
  end

  #----------------------------------------------
  # Various tokens
  #----------------------------------------------

  def set_tax(token, player, role)
    raise 'Only Game or action resolvers should call this method' if token != @action_token
    assert_in_array(role, @roles)
    assert_in_array(player, @players)
    @taxing_player = player
    @taxed_role = role
  end

  def set_treaty(token, player1, player2)
    raise 'Only Game or action resolvers should call this method' if token != @action_token
    raise "Can't treaty #{player1} with self" if player1 == player2
    assert_in_array(player1, @players)
    assert_in_array(player2, @players)
    @treaty_players = [player1, player2].freeze
  end

  def set_peace(token, player)
    raise 'Only Game or action resolvers should call this method' if token != @action_token
    assert_in_array(player, @players)
    @peace_player = player
  end

  #----------------------------------------------
  # Communications
  #----------------------------------------------

  def communications_add_player(token, player)
    raise 'Only Game or action resolvers should call this method' if token != @action_token
    player.each_live_card.each { |c| communications_add_card(player, c) }
  end

  def communications_add_deck(token, count)
    raise 'Only Game or action resolvers should call this method' if token != @action_token
    cards = @deck.shift(count)
    cards.each { |c|
      @communications_available << c
      @communications_assignments[c] = [nil, nil]
    }
  end

  #----------------------------------------------
  # Decision enqueuers (for action)
  #----------------------------------------------

  def enqueue_communications_decision(token, player, target = nil)
    raise 'Only Game or action resolvers should call this method' if token != @action_token
    @communications_available.sort_by!(&:role)
    @upcoming_decisions.unshift(lambda {
      Decision.single_player(
        current_turn.id, player, "Pick a card for #{target ? target.to_s : 'yourself'}?",
        choices: @communications_available.each_with_index.map { |card, i|
          ["pick#{i + 1}", Choice.new("Pick #{card}") { cb_communications_assign(target || player, card) }]
        }.to_h
      )
    })
  end

  def enqueue_lose_influence_decision(token, player)
    raise 'Only Game or action resolvers should call this method' if token != @action_token
    @upcoming_decisions.unshift(lambda {
      choices = player.each_live_card.with_index.map { |card, i|
        [0, { "lose#{i + 1}" => Choice.new("Lose #{card}") { cb_lose_card(player, card) }}]
      }
      @actions.select { |a| a.timing == :on_lose_influence }.each { |action|
        cost = tax_for(action)
        player.each_live_card.with_index { |card, i|
          text = "Claim #{card} is #{Role.to_s(action.required_role)}#{" (tax of #{cost} coin)" if cost > 0}"
          choices << [cost, { "#{action.slug}#{i + 1}" => Choice.new(text) { cb_react_to_lose_card(player, card, action) }}]
        }
      }
      Decision.single_player_with_costs(
        current_turn.id, player, 'Lose influence',
        costs_and_choices: choices
      )
    })
  end

  private

  def current_turn
    @turns.last
  end

  def current_player
    current_turn.active_player
  end

  def inactive_players
    @players - [current_player]
  end

  def player_loses_card(player, card)
    player.flip_card(@main_token, card)
    output("#{player} loses influence over a #{card} and now has #{player.influence} influence")

    if player.influence == 0
      @players.delete(player)
      @dead_players << player
      enqueue_on_death_decisions(player)
      @output_streams.each { |os| os.player_died(player.user) }
    end
  end

  # Removes card from player, switches with new from deck
  def replace_card_with_new(player, card)
    @deck << card
    @deck.shuffle!
    new_card = @deck.shift
    return if new_card == card
    # This will raise if player didn't have the old card
    player.replace_cards(@main_token, [card], [new_card])
    @output_streams.each { |os| os.new_cards(player.user) }
  end

  def communications_add_card(player, card)
    @communications_available << card
    @communications_assignments[card] = [player, nil]
  end

  def communications_commit
    return if @communications_assignments.empty?
    # This player_deltas is here for sanity checking.
    # Also Player#receive_cards will balk if I add cards without removing.
    # Hash[player => [cards_to_lose, cards_to_gain]]
    player_deltas = Hash.new { |h, k| h[k] = [[], []] }
    @communications_assignments.each { |card, (source, destination)|
      # Card is going to/from the same player, just skip it.
      next if source && source == destination
      player_deltas[source][0] << card if source
      if destination
        player_deltas[destination][1] << card
      else
        @deck << card
      end
    }

    # Player#replace_cards will do the sanity check
    player_deltas.each { |player, (lose, gain)|
      player.replace_cards(@main_token, lose, gain)
      @output_streams.each { |os| os.new_cards(player.user) }
    }

    @deck.shuffle!
    @communications_assignments.clear
  end

  #----------------------------------------------
  # Callbacks
  #----------------------------------------------

  def cb_action(player, action_class, args)
    parsed_args = []
    action_class.arguments.zip(args).each { |expected_arg, arg|
      return [false, "Missing an argument: #{expected_arg}"] unless arg

      if expected_arg.is_a?(Hash)
        raise "Malformed #{expected_arg} argument" unless expected_arg.size == 1
        arg_type = expected_arg.keys.first
        opts = expected_arg.values.first
      else
        arg_type = expected_arg
        opts = {}
      end

      case arg_type
      when :player
        target = find_player(arg)
        return [false, "No such player #{arg}"] unless target
        return [false, "Can't target yourself with #{action_class}"] if target == player && !opts[:self]
        unless opts[:friendly]
          # You can't target your treaty partner with anything unfriendly, not even Coup
          return [false, "Can't target #{target} because of Treaty"] if self.size > 2 && @treaty_players.include?(player) && @treaty_players.include?(target)
          # You can't target a peaced player with anything unfriendly except for Coup
          return [false, "Can only target #{target} with Coup because of Peace Keeping"] if @peace_player == target && action_class != Action::Coup
        end
        parsed_args << target
      when :role
        # No to_sym (Well, I'm on Ruby 2.2 so I can garbage-collect symbols, but I don't want to rely on it?)
        target = @roles.find { |r| r.to_s == arg.downcase }
        return [false, "No such role #{arg}"] unless target
        parsed_args << target
      else raise "Unexpected argument type #{expected_arg}"
      end
    }

    if action_class.targets_all
      targets = inactive_players
      targets.delete(@peace_player) if @peace_player
      targets -= @treaty_players if self.size > 2 && @treaty_players.include?(player)
      parsed_args.concat(targets)
    end

    action = action_class.new(*parsed_args)

    current_turn.action = action
    output("#{player} would like to use #{action}!")

    if action_class.required_role
      enqueue_challenge_decision_and_pay_tax(current_turn.action_claim)
      next_decision
    else
      join_phase
    end

    [true, '']
  end

  def cb_challenge(claim, challenger)
    claim.challenger = challenger
    if claim.type == :on_lose_influence
      output("#{challenger} challenges #{claim.claimant} to show that the set-aside card is #{Role.to_s(claim.role)}!")
      return cb_show_for_challenge(claim, claim.card, on_lose_influence: true)
    end
    enqueue_challenge_response_decision(claim, challenger)
    # No announcement needed since the decision will change.
    next_decision
    [true, '']
  end

  def cb_pass_challenge(claim, challenger)
    output("#{challenger} chooses not to challenge.")
    @current_decision.clear_player(challenger)
    # If no living players have a decision left to make, advance.
    generic_advance_phase unless @current_decision.valid_players.any?(&:alive?)
    [true, '']
  end

  def cb_join(turn, joiner)
    claim = turn.join(joiner)
    if claim.is_a?(Claim)
      output("#{joiner} would like to join in #{turn.action.class.flavor_name}!")
      enqueue_challenge_decision_and_pay_tax(claim)
      next_decision
    else
      output("#{joiner} joins in #{turn.action.class.flavor_name}!")
      generic_advance_phase
    end
    [true, '']
  end

  def cb_pass_join(turn, joiner)
    output("#{joiner} chooses not to join.")
    # Only one player should be up for joining at a time, so we can advance.
    generic_advance_phase
    [true, '']
  end

  def cb_block(turn, blocker)
    claim = turn.block(blocker)
    enqueue_challenge_decision_and_pay_tax(claim)
    output("#{blocker} would like to block #{turn.action.class.flavor_name}!")
    next_decision
    [true, '']
  end

  def cb_pass_block(turn, blocker)
    output("#{blocker} chooses not to block.")
    # Only one player should be up for blocking at a time, so we can advance.
    generic_advance_phase
    [true, '']
  end

  def cb_show_for_challenge(claim, card, on_lose_influence: false)
    if card.role == claim.role
      if on_lose_influence
        output("#{claim.claimant} was telling the truth! #{claim.claimant} reveals the [#{card}] that was set aside.")
        claim.claimant.flip_side_card(@main_token, card)
      else
        output("#{claim.claimant} was telling the truth! #{claim.claimant} shuffles [#{card}] into the deck.")
        replace_card_with_new(claim.claimant, card)
      end
      claim.truthful = true
      enqueue_lose_influence_decision(@action_token, claim.challenger)
      next_decision
    else
      output("#{claim.claimant} was lying! It was a #{card}, not a #{Role.to_s(claim.role)}! #{claim.claimant} can't #{claim.effect} this round.")
      claim.truthful = false
      if on_lose_influence
        claim.claimant.flip_side_card(@main_token, card)
        enqueue_lose_influence_decision(@action_token, claim.claimant)
        next_decision
      else
        player_loses_card(claim.claimant, card)
        generic_advance_phase
      end
    end
    [true, '']
  end

  def cb_lose_challenge_and_react(claim, card, action_class)
    output("#{claim.claimant} was lying! #{claim.claimant} can't #{claim.effect} this round.")
    claim.truthful = false
    cb_react_to_lose_card(claim.claimant, card, action_class)
  end

  def cb_claim_on_death(player, action_class, dead_player)
    output("#{player} would like to use #{action_class.new(dead_player)}!")
    new_claim = Claim.new(player, action_class, :on_death)
    @death_claims[action_class][dead_player] << new_claim
    enqueue_challenge_decision_and_pay_tax(new_claim)
    next_decision
    [true, '']
  end

  def cb_communications_assign(target, card)
    @communications_available.delete(card)
    @communications_assignments[card][1] = target
    generic_advance_phase
    [true, '']
  end

  def cb_lose_card(player, card)
    player_loses_card(player, card)
    generic_advance_phase
    [true, '']
  end

  def cb_react_to_lose_card(player, card, action_class)
    output("#{player} sets aside a card face-down and would like to use #{action_class.new}!")
    player.set_aside(@main_token, card, action_class.required_role)
    new_claim = Claim.new(player, action_class, :on_lose_influence, card: card)
    enqueue_reaction_resolution(new_claim)
    enqueue_challenge_decision_and_pay_tax(new_claim)
    next_decision
    [true, '']
  end

  #----------------------------------------------
  # Decision enqueuers
  #----------------------------------------------

  # OK fine, this one just returns it, but close enough.
  def decision_for_new_turn(player)
    # You must coup if you have >= 10 coins.
    actions_possible = player.coins >= 10 ? [Action::Coup] : @actions.select { |a| a.timing == :main_action }
    # If you can't afford an action it's not available to you.
    affordable, unaffordable = actions_possible.partition { |action| player.coins >= action.cost + tax_for(action) }

    # If you got another turn from your last action, nothing you do this turn can get you another.
    last_player = @turns.size >= 2 ? @turns[-2].active_player : nil
    too_many_turns, legal = affordable.partition { |action| last_player == player && action.another_turn? }

    Decision.single_player(
      current_turn.id, player, "#{player}'s turn to choose an action",
      choices: legal.map { |action|
        [action.slug, Choice.new(action.name_and_effect) { |args| cb_action(player, action, args) }]
      }.to_h,
      unavailable_choices: unaffordable.map { |action|
        [action.slug, "Need #{format_costs(action).join(' and ')}"]
      }.concat(too_many_turns.map { |action|
        [action.slug, 'Would cause three turns in a row']
      }).to_h
    )
  end

  def enqueue_multi_decision(turn, candidates, verb, yes_cb, no_cb, requires_role: true, base_cost: 0)
    return false if candidates.empty?

    candidates.each { |candidate|
      @upcoming_decisions.push(lambda {
        reqs = []
        tax = tax_for(turn.action.class)
        cost = tax
        if requires_role
          reqs << "also claiming #{Role.to_s(turn.action.class.required_role)}"
          reqs << "paying tax of #{tax} coin" if tax > 0
        end
        if base_cost > 0
          reqs << "paying #{base_cost} coins"
          cost += base_cost
        end

        Decision.single_player_with_costs(
          current_turn.id, candidate, "#{verb.capitalize} #{turn.active_player}'s #{turn.action.class.flavor_name} by #{reqs.join(' and ')}?",
          costs_and_choices: [
            [cost, { verb => Choice.new("#{verb.capitalize}!!!") { yes_cb.call(candidate) }}],
            [0, { 'pass' => Choice.new("Do not #{verb}") { no_cb.call(candidate) }}],
          ]
        )
      })
    }

    true
  end

  def enqueue_join_decision(turn)
    # The target shouldn't be joining (Protesters is example).
    candidates = inactive_players - turn.action.original_targets

    enqueue_multi_decision(
      turn, candidates, 'join',
      lambda { |candidate| cb_join(turn, candidate) },
      lambda { |candidate| cb_pass_join(turn, candidate) },
      requires_role: turn.action.class.join_requires_role,
      base_cost: turn.action.class.join_cost
    )
  end

  def enqueue_block_decision(turn)
    enqueue_multi_decision(
      turn, turn.action.potential_blockers, 'block',
      lambda { |candidate| cb_block(turn, candidate) },
      lambda { |candidate| cb_pass_block(turn, candidate) },
      requires_role: true,
      base_cost: 0
    )
  end

  def enqueue_challenge_decision_and_pay_tax(claim)
    # Since taxes always happen in conjunction with making a challengeable claim.
    pay_tax(claim.claimant, claim.action_class)

    @upcoming_decisions.unshift(lambda {
      text = claim.card ? 'the face-down card being' : 'having influence over'
      Decision.new(
        current_turn.id, "Challenge #{claim.claimant} on #{text} #{Role.to_s(claim.role)}?",
        choices: (@players - [claim.claimant]).map { |challenger|
          [challenger, {
            'challenge' => Choice.new('Challenge!!!') { cb_challenge(claim, challenger) },
            'pass' => Choice.new('Do not challenge') { cb_pass_challenge(claim, challenger) },
          }]
        }.to_h
      )
    })
  end

  def enqueue_challenge_response_decision(claim, challenger)
    player = claim.claimant
    @upcoming_decisions.unshift(lambda {
      choices = player.each_live_card.with_index.map { |card, i|
        [0, { "show#{i + 1}" => Choice.new("Show #{card}") { cb_show_for_challenge(claim, card) }}]
      }
      @actions.select { |a| a.timing == :on_lose_influence }.each { |action|
        cost = tax_for(action)
        player.each_live_card.with_index { |card, i|
          text = "Claim #{card} is #{Role.to_s(action.required_role)}#{" (tax of #{cost} coin)" if cost > 0}"
          choices << [cost, { "#{action.slug}#{i + 1}" => Choice.new(text) { cb_lose_challenge_and_react(claim, card, action) }}]
        }
      }
      Decision.single_player_with_costs(
        current_turn.id, player, "#{challenger} challenges #{player} on having influence over #{Role.to_s(claim.role)}",
        costs_and_choices: choices
      )
    })
  end

  def enqueue_on_death_decisions(dead_player)
    death_actions = @actions.select { |a| a.timing == :on_death }
    return false if death_actions.empty?
    death_actions.each { |action_class|
      @death_claims[action_class][dead_player] = []

      # Enqueue resolution "decision" to happen after everyone has made claims/challenges
      @upcoming_decisions.unshift(lambda {
        # Kind of freaky that the dead player is making the decision, but it should auto-resolve.
        successful_claimers = @death_claims[action_class][dead_player].select(&:truthful?).map(&:claimant)
        Decision.single_player(
          current_turn.id, dead_player, "Resolve #{action_class} for your death",
          choices: { 'resolve' => Choice.new('Resolve') {
            unless successful_claimers.empty?
              action = action_class.new(dead_player)
              verb = successful_claimers.size == 1 ? 'uses' : 'use'
              output("#{successful_claimers.join(', ')} #{verb} #{action_class.flavor_name}: #{action.effect}")
              action.resolve(self, @action_token, dead_player, successful_claimers, [dead_player])
            end
            generic_advance_phase
          }}
        )
      })
    }

    # Enqueue decision for each player * each on_death role
    # Reverse so that current player goes first
    # (we are doing unshift, not append, because these can chain)
    @players.reverse.each { |player|
      # There's only one on_death action right now.
      # If there ever were multiples, this code lets p1 decide whether to claim one or both, then p2, etc.
      # If that assumption ever turns out to be wrong, then modify this code.
      death_actions.each { |action|
        @upcoming_decisions.unshift(lambda {
          cost = tax_for(action)
          text = "Claim influence over #{Role.to_s(action.required_role)}#{" (tax of #{cost} coin)" if cost > 0}"
          Decision.single_player_with_costs(
            current_turn.id, player, "#{dead_player} died. #{text}?",
            costs_and_choices: [
              [cost, { "#{action.slug}" => Choice.new('Claim!!!') { cb_claim_on_death(player, action, dead_player) } }],
              [0, { 'pass' => Choice.new('Do not claim') { generic_advance_phase; [true, ''] } }],
            ]
          )
        })
      }
    }

    true
  end

  # This decision should get auto-resolved (it has one choice)
  # It's here to make sure the timing of the resolutions of on_lose_influence effects is right.
  def enqueue_reaction_resolution(claim)
    @upcoming_decisions.unshift(lambda {
      Decision.single_player(
        current_turn.id, claim.claimant, "Resolve your #{claim.action_class}",
        choices: { 'resolve' => Choice.new('Resolve') {
          action = claim.action_class.new
          output("#{claim.claimant} uses #{claim.action_class.flavor_name}: #{action.effect}")
          action.resolve(self, @action_token, claim.claimant, [], []) if claim.truthful?
          generic_advance_phase
        }}
      )
    })
  end

  #----------------------------------------------
  # Game phase changes
  #----------------------------------------------

  def next_decision
    upcoming = @upcoming_decisions.shift
    @current_decision = upcoming.call
    raise "#{@current_decision} not a Decision" unless @current_decision.is_a?(Decision)

    if @current_decision.empty?
      # Can happen when a lose influence decision targets a player who died to a challenge.
      # We can't auto-complete it because there's no callback, so advance.
      generic_advance_phase
    elsif @current_decision.can_auto_complete?
      # If we can auto-complete a decision, do it.

      unavailable = @current_decision.unavailable
      # Explain any unavailable decisions
      unless unavailable.empty?
        explanations = unavailable.each.map { |player, choices| "#{player} can't #{choices.join(', ')}" }.join(' - ')
        output("#{@current_decision.description} - #{explanations}")
      end
      @current_decision.auto_complete
      # Don't call advance_phase because the callback will do it =D
    elsif !@current_decision.valid_players.any?(&:alive?)
      # If decision is only by dead player, advance it.
      generic_advance_phase
    end
  end

  def generic_advance_phase
    if @upcoming_decisions.empty?
      case current_turn.state
      when :action; join_phase
      when :join; block_phase
      when :block; resolve_phase
      when :resolve; next_turn
      when :finished; raise "Can't advance #{current_turn.id}; turn ended"
      end
    else
      next_decision
    end
  end

  def join_phase
    current_turn.state = :join
    action_class = current_turn.action.class
    if current_turn.should_resolve? && action_class.joinable? && enqueue_join_decision(current_turn)
      next_decision
    else
      block_phase
    end
  end

  def block_phase
    current_turn.state = :block
    action_class = current_turn.action.class
    if current_turn.should_resolve? && action_class.blockable? && enqueue_block_decision(current_turn)
      next_decision
    else
      resolve_phase
    end
  end

  def resolve_phase
    current_turn.state = :resolve
    if current_turn.should_resolve?
      current_player.take_coins(@action_token, current_turn.action.class.cost)

      targets = current_turn.action.original_targets
      successful_joins = current_turn.successful_joins
      successful_blocks = current_turn.successful_blocks
      unblocked = targets - successful_blocks

      successful_joins.each { |joiner|
        joiner.take_coins(@action_token, current_turn.action.class.join_cost)
      }

      str = "#{current_player} uses #{current_turn.action.class.flavor_name}"
      str << " (joined by #{successful_joins.map(&:to_s).join(', ')})" unless successful_joins.empty?
      str << " (blocked by #{successful_blocks.map(&:to_s).join(', ')})" unless successful_blocks.empty?
      str << ": #{current_turn.action.effect(target_players: unblocked)}!"
      output(str)

      current_turn.action.resolve(self, @action_token, current_player, successful_joins, unblocked)
    end

    if @upcoming_decisions.empty?
      next_turn
    else
      next_decision
    end
  end

  def next_turn
    current_turn.state = :finished unless current_turn.nil?

    # It's possible that communication actions could enqueue an auto-completed decision for this.
    # Seems a bit clumsy to ask them to have to do that, so let's not.
    communications_commit

    # If the active player was killed, do not rotate.
    # Rotating would skip the player after the active player!
    if current_turn
      another_turn = current_turn.action.class.another_turn? && current_turn.should_resolve?
      active_player_killed = !current_turn.active_player.alive?
      @players.rotate! unless active_player_killed || another_turn
    else
      @players.rotate!
    end

    player = @players.first
    @turns << Turn.new(@turns.size + 1, player)

    @current_decision = decision_for_new_turn(player)
  end

  #----------------------------------------------
  # Misc stuff
  #----------------------------------------------

  def assert_in_array(player, array)
    raise "#{player} not in game #{@channel_name}" unless array.include?(player)
  end

  def tax_for(action)
    return 0 unless action.required_role
    action.required_role == @taxed_role ? 1 : 0
  end

  def pay_tax(player, action_class)
    return if !@taxing_player || player == @taxing_player
    tax = tax_for(action_class)
    return if tax == 0
    taken = player.take_coins(@action_token, tax)
    raise "#{player} can't afford tax of #{action_class}" if taken != tax
    output("#{player} pays the tax of #{tax} coin to #{@taxing_player}.")
    @taxing_player.give_coins(@action_token, tax)
  end

  def format_costs(action)
    [
      ("#{action.cost} coins for #{action.flavor_name}" if action.cost > 1),
      ("1 coin for #{action.flavor_name}" if action.cost == 1),
      ("#{tax_for(action)} coins for tax" if tax_for(action) > 1),
      ("1 coin for tax" if tax_for(action) == 1),
    ].compact
  end
end; end
