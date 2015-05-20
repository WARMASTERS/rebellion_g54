require 'spec_helper'

require 'rebellion_g54/action/judge'

RSpec.describe RebellionG54::Action::Judge do
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using judge' do
    let(:game) { example_game(2, coins: 3, roles: :judge) }
    before(:each) { game.take_choice(user, 'judge', opponent) }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
    end

    context 'when opponent passes' do
      before(:each) { game.take_choice(opponent, 'pass') }

      it 'asks opponent for block decision' do
        expect(game.choice_names).to be == { opponent => ['block', 'pass'] }
      end

      context 'when opponent blocks' do
        before(:each) { game.take_choice(opponent, 'block') }

        it 'asks me for challenge decision' do
          expect(game.choice_names).to be == { user => ['challenge', 'pass'] }
        end

        context 'when I pass' do
          before(:each) { game.take_choice(user, 'pass') }

          it 'takes my coins' do
            expect(game.user_coins(user)).to be == 0
          end

          it 'gives opponent coins' do
            expect(game.user_coins(opponent)).to be == 6
          end

          it 'ends my turn' do
            expect(game.current_user).to_not be == user
          end

          it 'does not decrease opponent influence' do
            expect(game.user_influence(opponent)).to be == 2
          end
        end
      end

      context 'when opponent passes' do
        before(:each) { game.take_choice(opponent, 'pass') }

        it 'asks opponent for lose decision' do
          expect(game.choice_names).to be == { opponent => ['lose1', 'lose2'] }
        end

        context 'when opponent loses a card' do
          before(:each) { game.take_choice(opponent, 'lose1') }

          it 'takes my coins' do
            expect(game.user_coins(user)).to be == 0
          end

          it 'gives opponent coins' do
            expect(game.user_coins(opponent)).to be == 6
          end

          it 'ends my turn' do
            expect(game.current_user).to_not be == user
          end

          it 'decreases opponent influence' do
            expect(game.user_influence(opponent)).to be == 1
          end
        end
      end
    end
  end
end
