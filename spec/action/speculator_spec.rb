require 'spec_helper'

require 'rebellion_g54/action/speculator'

RSpec.describe RebellionG54::Action::Speculator do
  # I'll ensure that I have at least one non-speculator card I can work with.
  let(:game) { example_game(2, rigged_roles: [:director], roles: [:speculator, :director]) }
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using speculator' do
    before(:each) { game.take_choice(user, 'speculator') }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
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

    context 'when opponent challenges and I show wrong card' do
      before(:each) do
        game.take_choice(opponent, 'challenge')
        game.take_choice(user, 'show1')
      end

      it 'takes all my coins' do
        expect(game.user_coins(user)).to be == 0
      end

      it 'gives my coins to opponent' do
        expect(game.user_coins(opponent)).to be == 4
      end

      it 'ends my turn' do
        expect(game.current_user).to_not be == user
      end
    end
  end
end
