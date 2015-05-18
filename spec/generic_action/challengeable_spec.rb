require 'spec_helper'

require 'rebellion_g54/action/base'

module RebellionG54; module Action
  class TestChallengeable < Base
    @flavor_name = 'Generic Challengeable'
    @description = 'Gain 2 coins'
    @required_role = :test_challengeable

    def resolve(game, token, active_player, join_players, target_players)
      active_player.give_coins(token, 2)
    end
  end

  class DummyRole < Base
  end
end; end

RSpec.describe RebellionG54::Action::TestChallengeable do
  let(:game) { example_game(2, roles: [:test_challengeable, :dummy_role], rigged_roles: [:test_challengeable, :dummy_role]) }
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using test_challengeable' do
    before(:each) { game.take_choice(user, 'test_challengeable') }

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

          it 'ends my turn' do
            expect(game.current_user).to_not be == user
          end

          it 'decreases opponent influence' do
            expect(game.user_influence(opponent)).to be == 1
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

      it 'gives me 2 coins' do
        expect(game.user_coins(user)).to be == 4
      end

      it 'ends my turn' do
        expect(game.current_user).to_not be == user
      end
    end
  end
end
