require 'spec_helper'

require 'rebellion_g54/action/farmer'

RSpec.describe RebellionG54::Action::Farmer do
  let(:game) { example_game(2, roles: :farmer) }
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using farmer' do
    before(:each) { game.take_choice(user, 'farmer', opponent) }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
    end

    context 'when opponent passes' do
      before(:each) { game.take_choice(opponent, 'pass') }

      it 'gives me net 2 coins' do
        expect(game.user_coins(user)).to be == 4
      end

      it 'gives opponent 1 coin' do
        expect(game.user_coins(opponent)).to be == 3
      end

      it 'ends my turn' do
        expect(game.current_user).to_not be == user
      end
    end
  end
end
