require 'spec_helper'

require 'rebellion_g54/action/politician'

RSpec.describe RebellionG54::Action::Politician do
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using politician' do
    let(:game) { example_game(2, roles: :politician) }
    before(:each) { game.take_choice(user, 'politician', opponent) }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
    end

    context 'when opponent passes' do
      before(:each) { game.take_choice(opponent, 'pass') }

      it 'asks opponent for block decision' do
        expect(game.choice_names).to be == { opponent => ['block', 'pass'] }
      end

      context 'when opponent passes' do
        before(:each) { game.take_choice(opponent, 'pass') }

        it 'gives me 2 coins' do
          expect(game.user_coins(user)).to be == 4
        end

        it 'takes 2 coins from opponent' do
          expect(game.user_coins(opponent)).to be == 0
        end

        it 'ends my turn' do
          expect(game.current_user).to_not be == user
        end
      end
    end
  end

  context 'when opponent has 1 coin' do
    let(:game) { example_game(2, roles: :politician, coins: 1) }
    before(:each) do
      game.take_choice(user, 'politician', opponent)
      game.take_choice(opponent, 'pass')
      game.take_choice(opponent, 'pass')
    end

    it 'gives me 1 coin' do
      expect(game.user_coins(user)).to be == 2
    end

    it 'takes 1 coin from opponent' do
      expect(game.user_coins(opponent)).to be == 0
    end

    it 'ends my turn' do
      expect(game.current_user).to_not be == user
    end
  end
end
