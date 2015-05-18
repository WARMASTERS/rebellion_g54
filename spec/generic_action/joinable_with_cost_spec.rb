require 'spec_helper'

require 'rebellion_g54/action/base'

module RebellionG54; module Action
  class TestJoinableWithCost < Base
    @flavor_name = 'Generic Joinable with cost'
    @description = 'Gain 1 coin, costs 1 coin to join'
    @required_role = :test_joinable_with_cost
    @joinable = true
    @join_cost = 1

    def resolve(game, token, active_player, join_players, target_players)
      active_player.give_coins(token, 1)
    end
  end

  class DummyRole < Base
  end
end; end

RSpec.describe RebellionG54::Action::TestJoinableWithCost do
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using test_joinable_with_cost' do
    let(:game) { example_game(2, roles: [:test_joinable_with_cost, :dummy_role], rigged_roles: [:test_joinable_with_cost, :dummy_role]) }
    before(:each) { game.take_choice(user, 'test_joinable_with_cost') }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
    end

    context 'when opponent challenges' do
      before(:each) { game.take_choice(opponent, 'challenge') }

      it 'asks me for show decision' do
        expect(game.choice_names).to be == { user => ['show1', 'show2'] }
      end

      context 'when showing right card' do
        before(:each) { game.take_choice(user, 'show1') }

        it 'asks opponent for lose decision' do
          expect(game.choice_names).to be == { opponent => ['lose1', 'lose2'] }
        end

        context 'when opponent flips' do
          before(:each) { game.take_choice(opponent, 'lose1') }

          # Going to assume that the rest works the same.

          it 'asks opponent for join decision' do
            expect(game.choice_names).to be == { opponent => ['join', 'pass'] }
          end
        end
      end

      context 'when showing wrong card' do
        before(:each) { game.take_choice(user, 'show2') }

        it 'gives me no coins' do
          expect(game.user_coins(user)).to be == 2
        end

        it 'decreases my influence' do
          expect(game.user_influence(user)).to be == 1
        end

        it 'ends my turn' do
          expect(game.current_user).to_not be == user
        end
      end
    end

    context 'when opponent passes' do
      before(:each) { game.take_choice(opponent, 'pass') }

      it 'asks opponent for join decision' do
        expect(game.choice_names).to be == { opponent => ['join', 'pass'] }
      end

      context 'when opponent joins' do
        before(:each) { game.take_choice(opponent, 'join') }

        it 'gives me coins' do
          expect(game.user_coins(user)).to be == 3
        end

        it 'takes opponent coins' do
          expect(game.user_coins(opponent)).to be == 1
        end

        it 'ends my turn' do
          expect(game.current_user).to_not be == user
        end
      end

      context 'when opponent passes' do
        before(:each) { game.take_choice(opponent, 'pass') }

        it 'gives me coins' do
          expect(game.user_coins(user)).to be == 3
        end

        it 'does not take opponent coins' do
          expect(game.user_coins(opponent)).to be == 2
        end

        it 'ends my turn' do
          expect(game.current_user).to_not be == user
        end
      end
    end
  end

  context 'when cannot afford join cost of test_joinable_with_cost' do
    let(:game) { example_game(2, coins: 0, roles: [:test_joinable_with_cost, :dummy_role], rigged_roles: [:test_joinable_with_cost, :dummy_role]) }

    before(:each) do
      game.take_choice(user, 'test_joinable_with_cost')
      game.take_choice(opponent, 'pass')
      # auto_complete should pick pass for the join decision.
    end

    it 'gives me coins' do
      expect(game.user_coins(user)).to be == 1
    end

    it 'does not take opponent coins' do
      expect(game.user_coins(opponent)).to be == 0
    end


    it 'ends my turn' do
      expect(game.current_user).to_not be == user
    end
  end
end
