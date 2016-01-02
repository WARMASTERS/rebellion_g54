# rebellion-g54

This is a Ruby implementation of game logic for "Coup: Guatemala 1954" or "Coup: Rebellion G54" by Rikki Tahta:

https://boardgamegeek.com/boardgame/148943/coup-rebellion-g54

[![Build Status](https://travis-ci.org/petertseng/rebellion_g54.svg?branch=master)](https://travis-ci.org/petertseng/rebellion_g54)

# Basic Usage

Call `RebellionG54::Game.new(channel_name: String, users: [User], roles: [Symbol])` to create a game.
`User` can be any type that is convenient, such as a string or any other form of user identifier.
Valid role symbols are listed in `lib/rebellion_g54/role.rb`.

Any time a decision is required of a player, the game presents a `Game#decision_description -> String` and `Game#choice_names -> Hash[User => String]` naming the choices each player can take.
Calling `Game#choice_explanations(User) -> Hash[String => Hash]` gives an explanation of each choice for that `User`, where each string is a choice name.
Each inner Hash is of the form:
`{description: String, args: [Hash], is_action: Boolean, available: Boolean}`
Additionally, the key `why_unavailable: String` is present if the choice is unavailable.
Each element of args is a Hash that at least contains the :type key, whose value may be :player or :role.
If :type is :player, the :self, :friendly, :richest, and :poorest keys may also be present, with boolean values.

When a player makes a choice, use `Game#take_choice(User, String(choice), *args) -> [Boolean(success), String(error)]`.
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
Any added lines that don't have coverage should have a very good reason for not being covered.
