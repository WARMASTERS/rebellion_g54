module RebellionG54; class Player
  attr_accessor :user
  attr_reader :coins
  attr_reader :alive
  alias :alive? :alive

  def initialize(user, main_token, action_token)
    @user = user
    @coins = 0
    @main_token = main_token
    @action_token = action_token

    # Being living is having the capability to make decisions.
    # Sometimes you have 0 live cards but are still alive.
    # For example, as a Missionary resolves.
    @alive = true

    # Live cards are face down. You can claim influence over them.
    @live_cards = []
    # Side cards are set aside face down. You cannot claim influence over them.
    # Hash[Card -> Role] (what role is each of these side cards claimed to be?)
    @side_cards = {}
    # Revealed cards are set aside face up. You cannot claim influence over them.
    @revealed_cards = []
  end

  def to_s
    @user.respond_to?(:name) ? @user.name : @user
  end

  def influence
    @live_cards.size
  end

  def each_live_card
    @live_cards.each
  end

  def each_side_card
    @side_cards.each
  end

  def each_revealed_card
    @revealed_cards.each
  end

  # These need the action token (game has it, but gives it out to the action resolvers)

  def give_coins(token, amount)
    raise 'Only Game or action resolvers should call this method' if token != @action_token
    @coins += amount
  end

  def take_coins(token, amount, strict: false)
    raise 'Only Game or action resolvers should call this method' if token != @action_token
    if amount > @coins
      raise "Can't take #{amount} coins from #{self} with #{@coins} coins" if strict
      taken = @coins
      @coins = 0
      return taken
    end
    @coins -= amount
    amount
  end

  # These need the main token (only game should have it)

  def die!(token)
    raise 'Only Game should call this method' if token != @main_token
    raise "#{self} has cards and should not die yet" if influence > 0
    @alive = false
  end

  def receive_cards(token, cards)
    raise 'Only Game should call this method' if token != @main_token
    cards.each { |c| @live_cards << c }
    raise "#{self} has too many cards: #{@live_cards}" if influence > Game::STARTING_INFLUENCE
  end

  def replace_cards(token, lose, gain)
    raise 'Only Game should call this method' if token != @main_token
    raise "#{self} receives unequal replacement #{lose} -> #{gain}" unless lose.size == gain.size
    lose.each { |c| raise "#{self} didn't have #{c}" unless @live_cards.delete(c) }
    receive_cards(token, gain)
  end

  def set_aside(token, card, claimed_role)
    raise 'Only Game should call this method' if token != @main_token
    removed = @live_cards.delete(card)
    raise "#{self} didn't have #{card}" unless removed
    @side_cards[removed] = claimed_role
  end

  def flip_card(token, card)
    raise 'Only Game should call this method' if token != @main_token
    removed = @live_cards.delete(card)
    raise "#{self} didn't have #{card}" unless removed
    @revealed_cards << removed
  end

  def flip_side_card(token, card)
    raise 'Only Game should call this method' if token != @main_token
    removed = @side_cards.delete(card)
    raise "#{self} didn't have #{card}" unless removed
    @revealed_cards << card
  end
end; end
