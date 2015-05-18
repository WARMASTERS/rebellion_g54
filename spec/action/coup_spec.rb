require 'spec_helper'

require 'rebellion_g54/action/coup'

RSpec.describe RebellionG54::Action::Coup do
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'with <= 6 coins' do
    let(:game) { example_game(2, coins: 6) }

    it 'is not available' do
      expect(game.choice_names[user]).to_not include('coup')
    end

    context 'when I try to perform coup' do
      before(:each) { @result = game.take_choice(user, 'coup', opponent) }

      it 'explains why I cannot' do
        expect(@result[0]).to be == false
        expect(@result[1]).to include('7 coin')
        expect(@result.size)
      end

      it 'is still my turn' do
        expect(game.current_user).to be == user
      end
    end
  end

  context 'with 7 coins' do
    let(:game) { example_game(2, coins: 7) }

    it 'is available' do
      expect(game.choice_names[user]).to include('coup')
    end

    it 'is not the only choice' do
      expect(game.choice_names[user].size).to be > 1
    end
  end

  context 'with >= 10 coins' do
    let(:game) { example_game(2, coins: 10) }

    it 'is the only choice available' do
      expect(game.choice_names).to be == { user => ['coup'] }
    end
  end

  context 'when using coup' do
    let(:game) { example_game(2, coins: 7) }
    before(:each) { game.take_choice(user, 'coup', opponent) }

    it 'costs money' do
      expect(game.user_coins(user)).to be == 0
    end

    it 'asks opponent for lose decision' do
      expect(game.choice_names).to be == { opponent => ['lose1', 'lose2'] }
    end

    context 'when opponent flips' do
      before(:each) { game.take_choice(opponent, 'lose1') }

      it 'ends my turn' do
        expect(game.current_user).to_not be == user
      end

      it 'decreases opponent influence' do
        expect(game.user_influence(opponent)).to be == 1
      end
    end
  end
end
