require 'simplecov'
SimpleCov.start { add_filter '/spec/' }

require 'rebellion_g54/game'

RSpec.configure { |c|
  c.warnings = true
  c.disable_monkey_patching!
}

# If roles given, put those roles in the game
# If rigged_roles given, give each player (up to 3) those roles
# If coins given, give everyone that many coins.
def example_game(num_players, freedom_of_press: false, synchronous_challenges: false, roles: nil, rigged_roles: nil, coins: nil)
  roles = [roles] if roles && !roles.is_a?(Array)
  roles = roles ? roles.dup : []

  # Always have a set of 5 cards even in tests.
  # Tests can go weird if some players start with < 2 cards.
  if roles.size < RebellionG54::Game::ROLES_PER_GAME
    default_roles = [:banker, :director, :guerrilla, :politician, :peacekeeper]
    new_roles = default_roles - roles
    roles.concat(new_roles.take(RebellionG54::Game::ROLES_PER_GAME - roles.size))
  end

  players = (1..num_players).map { |i| "p#{i}" }

  rig_opts = {}
  if rigged_roles
    rigged_roles = [rigged_roles] unless rigged_roles.is_a?(Array)
    rig_opts[:roles] = rigged_roles
  end
  rig_opts[:coins] = coins if coins

  opts = {
    strict_roles: false,
    synchronous_challenges: synchronous_challenges,
    freedom_of_press_enabled: freedom_of_press,
  }
  opts[:rigged_players] = [rig_opts] * num_players unless rig_opts.empty?

  RebellionG54::Game.new('testgame', players, roles, **opts)
end

class CollectingStream
  attr_reader :dead_players, :new_cards_players, :messages

  def initialize
    @dead_players = []
    @new_cards_players = []
    @messages = []
  end

  def player_died(player)
    @dead_players << player
  end

  def new_cards(player)
    @new_cards_players << player
  end

  def puts(msg)
    @messages << msg
  end
end

class StdoutStream
  def player_died(player)
    puts("#{player} died")
  end
  def new_cards(player)
    puts("#{player} new cards")
  end
  def puts(msg)
    $stdout.puts(msg)
  end
end
