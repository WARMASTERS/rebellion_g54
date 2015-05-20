require 'spec_helper'

require 'rebellion_g54/action/spy'

RSpec.describe RebellionG54::Action::Spy do
  let(:game) { example_game(2, roles: :spy) }
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using spy' do
    before(:each) { game.take_choice(user, 'spy', opponent) }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
    end

    context 'when opponent passes' do
      before(:each) { game.take_choice(opponent, 'pass') }

      it 'gives me a coin' do
        expect(game.user_coins(user)).to be == 3
      end

      it 'is still my turn' do
        expect(game.current_user).to be == user
      end

      it 'does not let me use spy again' do
        expect(game.choice_names[user]).to_not include('spy')
      end

      it 'fails if I try to use spy anyway' do
        success, _ = game.take_choice(user, 'spy')
        expect(success).to be == false
      end

      it 'tells me why I cannot use spy' do
        _, error = game.take_choice(user, 'spy')
        expect(error).to include('in a row')
      end
    end
  end
end
