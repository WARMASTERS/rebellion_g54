require 'spec_helper'

require 'rebellion_g54/action/base'

module RebellionG54; module Action
  class TestOnLoseInfluence < Base
    @flavor_name = 'Generic On Lose Influence'
    @description = 'Gain 5 coins'
    @required_role = :test_on_lose_influence
    @timing = :on_lose_influence
    @responds_to_coup = true

    def resolve(game, token, active_player, _, _)
      active_player.give_coins(token, 5)
    end
  end

  class TestRole < Base
    @flavor_name = 'Test role'
    @description = 'Does nothing but requires a character'
    @required_role = :test_role
  end
end; end

RSpec.describe RebellionG54::Action::TestOnLoseInfluence do
  let(:game) { example_game(2, coins: 7, roles: [:test_on_lose_influence, :test_role], rigged_roles: [:test_on_lose_influence, :test_role]) }
  let(:user) { game.choice_names.keys.first }

  it 'does not include test_on_lose_influence' do
    expect(game.choice_names[user]).to_not include('test_on_lose_influence')
  end

  shared_examples 'an on_lose_influence action' do
    context 'when opponent sets right card' do
      before(:each) { game.take_choice(opponent, 'test_on_lose_influence1') }

      it 'decreases opponent influence' do
        expect(game.user_influence(opponent)).to be == 1
      end

      it 'has a side card for the opponent' do
        player = game.find_player(opponent)
        side_cards = player.each_side_card.map { |card, claim_role| [card.role, claim_role] }
        expect(side_cards).to be == [[:test_on_lose_influence, :test_on_lose_influence]]
      end

      it 'asks me for challenge decision' do
        expect(game.choice_names).to be == { user => ['challenge', 'pass'] }
      end

      context 'when I challenge' do
        before(:each) { game.take_choice(user, 'challenge') }

        it 'removes side card for the opponent' do
          player = game.find_player(opponent)
          side_cards = player.each_side_card.map { |c| c }
          expect(side_cards).to be_empty
        end

        it 'adds revealed card for the opponent' do
          player = game.find_player(opponent)
          revealed_cards = player.each_revealed_card.map { |c| c.role }
          expect(revealed_cards).to be == [:test_on_lose_influence]
        end

        it 'asks me for lose decision' do
          expect(game.choice_names).to be == { user => [
            'lose1', 'lose2', 'test_on_lose_influence1', 'test_on_lose_influence2'
          ]}
        end

        context 'when I lose a card' do
          before(:each) { game.take_choice(user, 'lose1') }

          it 'gives opponent coins' do
            expect(game.user_coins(opponent)).to be == 12
          end

          it 'ends my turn' do
            expect(game.current_user).to be == final_player
          end
        end
      end

      context 'when I pass' do
        before(:each) { game.take_choice(user, 'pass') }

        it 'gives opponent coins' do
          expect(game.user_coins(opponent)).to be == 12
        end

        it 'ends my turn' do
          expect(game.current_user).to be == final_player
        end
      end
    end

    context 'when opponent sets wrong card' do
      before(:each) { game.take_choice(opponent, 'test_on_lose_influence2') }

      it 'decreases opponent influence' do
        expect(game.user_influence(opponent)).to be == 1
      end

      it 'has a side card for the opponent' do
        player = game.find_player(opponent)
        side_cards = player.each_side_card.map { |card, claim_role| [card.role, claim_role] }
        expect(side_cards).to be == [[:test_role, :test_on_lose_influence]]
      end

      it 'asks me for challenge decision' do
        expect(game.choice_names).to be == { user => ['challenge', 'pass'] }
      end

      context 'when I challenge' do
        before(:each) { game.take_choice(user, 'challenge') }

        it 'removes side card for the opponent' do
          player = game.find_player(opponent)
          side_cards = player.each_side_card.map { |c| c }
          expect(side_cards).to be_empty
        end

        it 'adds revealed card for the opponent' do
          player = game.find_player(opponent)
          revealed_cards = player.each_revealed_card.map { |c| c.role }
          expect(revealed_cards).to be == [:test_role]
        end

        it 'asks opponent for lose decision' do
          expect(game.choice_names).to be == { opponent => [
            'lose1', 'test_on_lose_influence1'
          ]}
        end

        context 'when opponent loses card' do
          before(:each) { game.take_choice(opponent, 'lose1') }

          it 'eliminates opponent' do
            expect(game.size).to be == 1
          end

          it 'does not give opponent coins' do
            # Can't use user_coins. Opponent is dead.
            expect(game.find_dead_player(opponent).coins).to be == 7
          end
        end
      end

      context 'when I pass' do
        before(:each) { game.take_choice(user, 'pass') }

        it 'gives opponent coins' do
          expect(game.user_coins(opponent)).to be == 12
        end

        it 'ends my turn' do
          expect(game.current_user).to be == final_player
        end
      end
    end
  end

  context 'when using coup on opponent' do
    let(:opponent) { game.users.last }
    let(:final_player) { opponent }
    before(:each) { game.take_choice(user, 'coup', opponent) }

    it 'asks opponent for lose decision' do
      expect(game.choice_names).to be == { opponent => [
        'lose1', 'lose2', 'test_on_lose_influence1', 'test_on_lose_influence2'
      ]}
    end

    it_should_behave_like 'an on_lose_influence action'
  end

  context 'when challenging opponent' do
    let!(:opponent) { game.users.last }
    let(:final_player) { user }

    # I use income so the test can use the same players as the other on_lose_influence test
    before(:each) do
      game.take_choice(user, 'income')
      game.take_choice(opponent, 'test_role')
      game.take_choice(user, 'challenge')
    end

    it 'asks opponent for show decision' do
      expect(game.choice_names).to be == { opponent => [
        'show1', 'show2', 'test_on_lose_influence1', 'test_on_lose_influence2'
      ]}
    end

    it_should_behave_like 'an on_lose_influence action'
  end

  context 'when claiming on your last influence' do
    let(:game) { example_game(3, coins: 7, roles: [:test_on_lose_influence, :test_role], rigged_roles: [:test_on_lose_influence, :test_role]) }
    let(:users) { game.users }
    let!(:u1) { users[0] }
    let!(:u2) { users[1] }
    let!(:u3) { users[2] }

    before(:each) do
      game.take_choice(u1, 'coup', u3)
      game.take_choice(u3, 'lose1')
      game.take_choice(u2, 'coup', u3)
      game.take_choice(u3, 'test_on_lose_influence1')
      game.take_choice(u2, 'pass')
      game.take_choice(u1, 'pass')
    end

    it 'removes u3 from the game' do
      expect(game.users).to_not include(u3)
    end

    it 'considers u3 to be dead' do
      expect(game.find_player(u3)).to be_nil
      expect(game.find_dead_player(u3)).to_not be_nil
    end

    it 'skips u3 in turn order' do
      expect(game.current_user).to_not be == u3
      expect(game.current_user).to be == u1
    end
  end
end
