require 'spec_helper'

require 'rebellion_g54/game'

RSpec.describe RebellionG54::Game do
  context 'in a three-player game' do
    let(:game) { example_game(3, coins: 7, rigged_roles: :guerrilla) }
    let(:users) { game.users }
    let!(:u1) { users[0] }
    let!(:u2) { users[1] }
    let!(:u3) { users[2] }

    context 'when eliminating a player' do
      before(:each) do
        game.take_choice(u1, 'coup', u3)
        game.take_choice(u3, 'lose1')
        game.take_choice(u2, 'coup', u3)
        # auto-complete should automatically use lose1 for u3
      end

      it 'removes the player' do
        expect(game.size).to be == 2
      end

      it 'has a dead player' do
        player = game.find_dead_player(u3)
        expect(game.each_dead_player.map { |p| p }).to be == [player]
      end

      it 'has revealed cards for the player' do
        player = game.find_dead_player(u3)
        expect(player.each_revealed_card.map { |c| c }.size).to be == 2
      end

      it 'does not declare the game over yet' do
        expect(game.winner).to be_nil
      end
    end

    context 'when doubly-eliminating a 1-influence player' do
      before(:each) do
        game.take_choice(u1, 'coup', u3)
        game.take_choice(u3, 'lose1')
        game.take_choice(u2, 'guerrilla', u3)
        game.take_choice(u3, 'challenge')
        game.take_choice(u2, 'show1')
      end

      it 'removes the player' do
        expect(game.size).to be == 2
      end

      it 'does not declare the game over yet' do
        expect(game.winner).to be_nil
      end

      it 'ends the turn' do
        expect(game.current_user).to_not be == u2
      end

      it 'skips the dead player in turn order' do
        expect(game.current_user).to_not be == u3
      end
    end
  end

  context 'in a two-player game' do
    let(:game) { example_game(2, coins: 14) }
    let(:users) { game.users }
    let!(:u1) { users[0] }
    let!(:u2) { users[1] }

    context 'when eliminating a player' do
      before(:each) do
        game.take_choice(u1, 'coup', u2)
        game.take_choice(u2, 'lose1')
        # u2 has to coup u1 instead of income, doh
        game.take_choice(u2, 'coup', u1)
        game.take_choice(u1, 'lose1')
        game.take_choice(u1, 'coup', u2)
        # auto-complete should automatically use lose1 for u2
      end

      it 'removes the player' do
        expect(game.size).to be == 1
      end

      it 'declares a winner' do
        expect(game.winner).to be == u1
      end
    end
  end
end
