require 'spec_helper'

require 'rebellion_g54/action/freedom_of_press'

RSpec.describe RebellionG54::Action::Director do
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using freedom of press' do
    let(:game) { example_game(2, freedom_of_press: true) }
    before(:each) { game.take_choice(user, 'freedom_of_press') }

    it 'asks me for pick decision' do
      expect(game.choice_names).to be == { user => ['pick1', 'pick2', 'pick3'] }
    end

    context 'when I pick first card' do
      before(:each) { game.take_choice(user, 'pick1') }

      it 'asks me for pick decision' do
        expect(game.choice_names).to be == { user => ['pick1', 'pick2'] }
      end

      context 'when I pick second card' do
        before(:each) { game.take_choice(user, 'pick1') }

        it 'maintains my influence' do
          expect(game.user_influence(user)).to be == 2
        end

        it 'ends my turn' do
          expect(game.current_user).to_not be == user
        end
      end
    end
  end

  context 'in game without freedom of press' do
    let(:game) { example_game(2, freedom_of_press: false) }

    it 'is not available' do
      expect(game.choice_names[user]).to_not include('freedom_of_press')
    end
  end
end
