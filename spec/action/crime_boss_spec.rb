require 'spec_helper'

require 'rebellion_g54/action/crime_boss'

RSpec.describe RebellionG54::Action::CrimeBoss do
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using crime_boss' do
    let(:game) { example_game(2, coins: 5, roles: :crime_boss) }
    before(:each) { game.take_choice(user, 'crime_boss', opponent) }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
    end

    context 'when opponent passes' do
      before(:each) { game.take_choice(opponent, 'pass') }

      it 'asks opponent for lose/pay decision' do
        expect(game.choice_names).to be == { opponent => ['lose1', 'lose2', 'pay'] }
      end

      context 'when opponent pays' do
        before(:each) { game.take_choice(opponent, 'pay') }

        it 'gives me coins' do
          expect(game.user_coins(user)).to be == 7
        end

        it 'takes opponent coins' do
          expect(game.user_coins(opponent)).to be == 3
        end

        it 'ends my turn' do
          expect(game.current_user).to_not be == user
        end

        it 'does not decrease opponent influence' do
          expect(game.user_influence(opponent)).to be == 2
        end
      end

      context 'when opponent loses card' do
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

  context 'when dying to challenge before responding to a crime boss action' do
    let(:game) { example_game(3, coins: 7, roles: [:crime_boss, :banker], rigged_roles: [:crime_boss, :banker]) }
    let(:users) { game.users }
    let!(:u1) { users[0] }
    let!(:u2) { users[1] }
    let!(:u3) { users[2] }

    before(:each) do
      game.take_choice(u1, 'coup', u3)
      game.take_choice(u3, 'lose1')
      game.take_choice(u2, 'crime_boss', u3)
      game.take_choice(u3, 'challenge')
      game.take_choice(u2, 'show1')
    end

    # This is an each_live_card choice mixed with a static choice.
    # If used on a dead player, each_live_card results in no choices.
    # If implemented naively, auto-complete will pick the static choice.
    # We want instead for no choice to be taken (the target is dead!)

    it 'does not give crime boss any coins' do
      expect(game.user_coins(u2)).to be == 2
    end

    it 'ends the turn' do
      expect(game.current_user).to_not be == u2
    end

    it 'removes target from the game' do
      expect(game.find_player(u3)).to be_nil
      expect(game.find_dead_player(u3)).to_not be_nil
    end
  end
end
