# rebellion-g54

This is a Ruby implementation of game logic for "Coup: Guatemala 1954" or "Coup: Rebellion G54" by Rikki Tahta:

https://boardgamegeek.com/boardgame/148943/coup-rebellion-g54

# Basic Usage

Create an instance of `RebellionG54::Game`, use `Game#add_player(User)` to add some players (`User` can be any type that is convenient, such as a string or any other form of user identifier), `Game#roles=`, to change the roles, then `Game#start_game` to start it.

Any time a decision is required of a player, the game presents a `Game#decision_description -> String` and `Game#choice_names -> Hash[User => String]` naming the choices each player can take.
Calling `Game#choice_explanations(User) -> Hash[String => Hash]` gives an explanation of each choice for that `User`, where each string is a choice name.
Each inner Hash is of the form:
`{description: String, needs_args: Boolean, available: true}` if that choice is available.
`{why_unavailable: String, available: false}` if that choice is unavailable.

When a player makes a choice, use `Game#take_choice(User, String(choice), String(args)) -> [Boolean(success), String(error)]`.
If failed, the `error` will describe why.
If successful, the game state will be updated, `error` will be an empty string, and a new decision will be available.

The game is won when `Game#winner -> User?` returns a `User`.
If the game is not won, `Game#winner` returns `nil`.

# Tests

The automated tests are run with `rspec`.
Running automatically generates a coverage report (made with [simplecov](https://github.com/colszowka/simplecov)).

If a bug is found in the game logic, write a test that fails with the broken logic, then fix the game logic.

If a new feature is added, a test should be added.
Coverage should remain high.
As of this writing, only three lines are not covered.
