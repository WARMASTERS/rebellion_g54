require 'spec_helper'

require 'rebellion_g54/action/banker'

RSpec.describe RebellionG54::Action::Banker do
  let(:game) { example_game(2, roles: :banker) }
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using banker' do
    before(:each) { game.take_choice(user, 'banker') }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
    end

    context 'when opponent passes' do
      before(:each) { game.take_choice(opponent, 'pass') }

      it 'gives me 3 coins' do
        expect(game.user_coins(user)).to be == 5
      end

      it 'ends my turn' do
        expect(game.current_user).to_not be == user
      end
    end
  end
end
