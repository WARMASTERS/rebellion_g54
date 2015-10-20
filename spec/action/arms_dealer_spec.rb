require 'spec_helper'

require 'rebellion_g54/action/arms_dealer'

RSpec.describe RebellionG54::Action::ArmsDealer do
  let(:game) { example_game(2, roles: [:arms_dealer, :banker, :director]) }
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using arms_dealer' do
    before(:each) { game.take_choice(user, 'arms_dealer', 'banker') }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
    end

    context 'when opponent passes' do
      before(:each) { game.take_choice(opponent, 'pass') }

      # Randomness means I don't know which outcome I got.
      # But I still test this to make sure it works without stubbing.
      it 'ends my turn' do
        expect(game.current_user).to_not be == user
      end
    end

    context 'on successful guess' do
      before(:each) do
        expect(game).to receive(:random_deck_roles).with(anything, 2).and_return([:banker, :director])
        game.take_choice(opponent, 'pass')
      end

      it 'gives me 4 coins' do
        expect(game.user_coins(user)).to be == 6
      end

      it 'ends my turn' do
        expect(game.current_user).to_not be == user
      end
    end

    context 'on unsuccessful guess' do
      before(:each) do
        expect(game).to receive(:random_deck_roles).with(anything, 2).and_return([:director, :director])
        game.take_choice(opponent, 'pass')
      end

      it 'gives me no coins' do
        expect(game.user_coins(user)).to be == 2
      end

      it 'ends my turn' do
        expect(game.current_user).to_not be == user
      end
    end
  end
end
