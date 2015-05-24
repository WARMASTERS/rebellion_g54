require 'spec_helper'

require 'rebellion_g54/action/communist'

RSpec.describe RebellionG54::Action::Communist do
  context 'when using communist' do
    let(:game) { example_game(2, roles: :communist, coins: 4) }
    let(:user) { game.choice_names.keys.first }
    let(:opponent) { game.users.last }
    before(:each) { game.take_choice(user, 'communist', "#{opponent} #{user}") }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
    end

    context 'when opponent passes' do
      before(:each) { game.take_choice(opponent, 'pass') }

      it 'asks opponent for block decision' do
        expect(game.choice_names).to be == { opponent => ['block', 'pass'] }
      end

      context 'when opponent blocks' do
        before(:each) do
          game.take_choice(opponent, 'block')
          game.take_choice(user, 'pass')
        end

        it 'does not give me coins' do
          expect(game.user_coins(user)).to be == 4
        end

        it 'does not take coins from opponent' do
          expect(game.user_coins(opponent)).to be == 4
        end

        it 'ends my turn' do
          expect(game.current_user).to_not be == user
        end
      end

      context 'when opponent passes' do
        before(:each) { game.take_choice(opponent, 'pass') }

        it 'gives me 3 coins' do
          expect(game.user_coins(user)).to be == 7
        end

        it 'takes 3 coins from opponent' do
          expect(game.user_coins(opponent)).to be == 1
        end

        it 'ends my turn' do
          expect(game.current_user).to_not be == user
        end
      end
    end
  end

  context 'when taking coins from myself' do
    let(:game) { example_game(2, roles: :communist, coins: 4) }
    let(:user) { game.choice_names.keys.first }
    let(:opponent) { game.users.last }
    before(:each) { game.take_choice(user, 'communist', "#{user} #{opponent}") }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
    end

    context 'when opponent passes' do
      before(:each) { game.take_choice(opponent, 'pass') }

      # Should not ask me to block.

      it 'takes 3 coins from me' do
        expect(game.user_coins(user)).to be == 1
      end

      it 'gives opponent 3 coins' do
        expect(game.user_coins(opponent)).to be == 7
      end

      it 'ends my turn' do
        expect(game.current_user).to_not be == user
      end
    end
  end

  context 'when money is uneven' do
    let(:game) { example_game(3, roles: [:communist, :banker]) }
    let(:users) { game.users }
    let!(:u1) { users[0] }
    let!(:u2) { users[1] }
    let!(:u3) { users[2] }

    before(:each) do
      game.take_choice(u1, 'banker')
      game.take_choice(u2, 'pass')
      game.take_choice(u3, 'pass')
      game.take_choice(u2, 'income')
    end

    it 'complains if first target is not richest' do
      success, error = game.take_choice(u3, 'communist', "#{u2} #{u3}")
      expect(error).to include('not the richest')
      expect(success).to be == false
    end

    it 'complains if second target is not poorest' do
      success, error = game.take_choice(u3, 'communist', "#{u1} #{u2}")
      expect(error).to include('not the poorest')
      expect(success).to be == false
    end

    it 'succeeds if targets are correct' do
      success, _ = game.take_choice(u3, 'communist', "#{u1} #{u3}")
      expect(success).to be == true
    end
  end
end
