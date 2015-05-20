require 'spec_helper'

require 'rebellion_g54/action/crime_boss'

RSpec.describe RebellionG54::Action::CrimeBoss do
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using crime_boss' do
    let(:game) { example_game(2, coins: 5, roles: :crime_boss) }
    before(:each) { game.take_choice(user, 'crime_boss', opponent) }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
    end

    context 'when opponent passes' do
      before(:each) { game.take_choice(opponent, 'pass') }

      it 'asks opponent for lose/pay decision' do
        expect(game.choice_names).to be == { opponent => ['lose1', 'lose2', 'pay'] }
      end

      context 'when opponent pays' do
        before(:each) { game.take_choice(opponent, 'pay') }

        it 'gives me coins' do
          expect(game.user_coins(user)).to be == 7
        end

        it 'takes opponent coins' do
          expect(game.user_coins(opponent)).to be == 3
        end

        it 'ends my turn' do
          expect(game.current_user).to_not be == user
        end

        it 'does not decrease opponent influence' do
          expect(game.user_influence(opponent)).to be == 2
        end
      end

      context 'when opponent loses card' do
        before(:each) { game.take_choice(opponent, 'lose1') }

        it 'takes my coins' do
          expect(game.user_coins(user)).to be == 0
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
