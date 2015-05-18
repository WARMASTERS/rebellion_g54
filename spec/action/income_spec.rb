require 'spec_helper'

require 'rebellion_g54/action/income'

RSpec.describe RebellionG54::Action::Income do
  let(:game) { example_game(2) }

  context 'when using income' do
    let(:user) { game.choice_names.keys.first }
    before(:each) { game.take_choice(user, 'income') }

    it 'gives me a coin' do
      expect(game.user_coins(user)).to be == 3
    end

    it 'ends my turn' do
      expect(game.current_user).to_not be == user
    end
  end
end
