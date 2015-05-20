require 'simplecov'
SimpleCov.start { add_filter '/spec/' }

require 'rebellion_g54/game'

# If roles given, put those roles in the game
# If rigged_roles given, give each player (up to 3) those roles
# If coins given, give everyone that many coins.
def example_game(num_players, roles: nil, rigged_roles: nil, coins: nil)
  game = RebellionG54::Game.new('testgame')

  if roles
    roles = [roles] unless roles.is_a?(Array)
    game.roles = roles
  end

  # Always have a set of 5 cards even in tests.
  # Tests can go weird if some players start with < 2 cards.
  if game.roles.size < RebellionG54::Game::ROLES_PER_GAME
    default_roles = [:banker, :director, :guerrilla, :politician, :peacekeeper]
    new_roles = default_roles - game.roles
    game.roles.concat(new_roles.take(RebellionG54::Game::ROLES_PER_GAME - game.roles.size))
  end

  num_players.times { |i| game.add_player("p#{i + 1}") }

  rig_opts = {}
  if rigged_roles
    rigged_roles = [rigged_roles] unless rigged_roles.is_a?(Array)
    rig_opts[:roles] = rigged_roles
  end
  rig_opts[:coins] = coins if coins

  if rig_opts.empty?
    game.start_game(strict_roles: false)
  else
    game.start_game(strict_roles: false, rigged_players: [rig_opts] * num_players)
  end

  game
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
