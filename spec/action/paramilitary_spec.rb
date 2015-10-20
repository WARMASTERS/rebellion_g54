require 'spec_helper'

require 'rebellion_g54/action/paramilitary'

RSpec.describe RebellionG54::Action::Paramilitary do
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using paramilitary on two-influence player' do
    let(:game) { example_game(2, coins: 3, roles: :paramilitary) }
    before(:each) { game.take_choice(user, 'paramilitary', opponent) }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
    end

    context 'when opponent passes' do
      before(:each) { game.take_choice(opponent, 'pass') }

      it 'asks opponent for block decision' do
        expect(game.choice_names).to be == { opponent => ['block', 'pass'] }
      end

      context 'when opponent blocks' do
        before(:each) { game.take_choice(opponent, 'block') }

        it 'asks me for challenge decision' do
          expect(game.choice_names).to be == { user => ['challenge', 'pass'] }
        end

        context 'when I pass' do
          before(:each) { game.take_choice(user, 'pass') }

          it 'takes my coins' do
            expect(game.user_coins(user)).to be == 0
          end

          it 'ends my turn' do
            expect(game.current_user).to_not be == user
          end

          it 'does not decrease opponent influence' do
            expect(game.user_influence(opponent)).to be == 2
          end
        end
      end

      context 'when opponent passes' do
        before(:each) { game.take_choice(opponent, 'pass') }

        it 'asks opponent for lose decision' do
          expect(game.choice_names).to be == { opponent => ['lose1', 'lose2'] }
        end

        context 'when opponent loses a card' do
          before(:each) { game.take_choice(opponent, 'lose1') }

          it 'takes my coins' do
            expect(game.user_coins(user)).to be == 0
          end

          it 'ends my turn' do
            expect(game.current_user).to_not be == user
          end

          it 'decreases opponent influence' do
            expect(game.user_influence(opponent)).to be == 1
          end
        end
      end
    end
  end

  context 'without enough coins to use paramilitary on one-influence player' do
    let(:game) { example_game(2, coins: 7, roles: :paramilitary) }
    before(:each) do
      game.take_choice(user, 'paramilitary', opponent)
      # pass on challenge, pass on block, lose card.
      game.take_choice(opponent, 'pass')
      game.take_choice(opponent, 'pass')
      game.take_choice(opponent, 'lose1')
      game.take_choice(opponent, 'income')
    end

    it 'disallows paramilitary' do
      success, _ = game.take_choice(user, 'paramilitary', opponent)
      expect(success).to be == false
    end

    it 'explains why paramilitary is disallowed' do
      _, err = game.take_choice(user, 'paramilitary', opponent)
      expect(err).to include('2 coins')
      expect(err).to include('with 1 influence')
    end
  end

  context 'when using paramilitary on one-influence player' do
    let(:game) { example_game(3, coins: 7, roles: :paramilitary) }
    let(:users) { game.users }
    let!(:u1) { users[0] }
    let!(:u2) { users[1] }
    let!(:u3) { users[2] }

    before(:each) do
      game.take_choice(u1, 'paramilitary', u3)
      # pass on challenge
      game.take_choice(u2, 'pass')
      game.take_choice(u3, 'pass')
      # pass on block, lose card
      game.take_choice(u3, 'pass')
      game.take_choice(u3, 'lose1')

      success, _ = game.take_choice(u2, 'paramilitary', u3)
      expect(success).to be == true

      # pass on challenge
      game.take_choice(u3, 'pass')
      game.take_choice(u1, 'pass')
      # pass on block (lose card happens automatically)
      game.take_choice(u3, 'pass')
    end

    it 'takes my coins' do
      expect(game.user_coins(u2)).to be == 2
    end
  end
end
