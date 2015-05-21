require 'spec_helper'

require 'rebellion_g54/action/newscaster'

RSpec.describe RebellionG54::Action::Newscaster do
  let(:game) { example_game(2, roles: [:newscaster, :banker, :politician]) }
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using newscaster' do
    before(:each) { game.take_choice(user, 'newscaster') }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
    end

    context 'when opponent passes' do
      before(:each) { game.take_choice(opponent, 'pass') }

      it 'asks me for pick decision' do
        expect(game.choice_names).to be == { user => ['pick1', 'pick2', 'pick3', 'pick4', 'pick5'] }
      end

      context 'when I pick first card' do
        before(:each) { game.take_choice(user, 'pick1') }

        it 'asks me for pick decision' do
          expect(game.choice_names).to be == { user => ['pick1', 'pick2', 'pick3', 'pick4'] }
        end

        context 'when I pick second card' do
          before(:each) { game.take_choice(user, 'pick1') }

          it 'costs me a coin' do
            expect(game.user_coins(user)).to be == 1
          end

          it 'maintains my influence' do
            expect(game.user_influence(user)).to be == 2
          end

          it 'ends my turn' do
            expect(game.current_user).to_not be == user
          end
        end
      end
    end
  end

  # This test makes sure state is cleaned up between communications actions.
  # It was not originally, so the second communications action would break.
  # This is one of the first bugs discovered in real playtesting!
  context 'when using newscaster twice in the same game' do
    before(:each) do
      game.take_choice(user, 'newscaster')
      game.take_choice(opponent, 'pass')
      game.take_choice(user, 'pick1')
      game.take_choice(user, 'pick2')
      game.take_choice(opponent, 'newscaster')
      game.take_choice(user, 'pass')
      game.take_choice(opponent, 'pick1')
      game.take_choice(opponent, 'pick2')
    end

    it 'has taken coins from both players' do
      expect(game.user_coins(user)).to be == 1
      expect(game.user_coins(opponent)).to be == 1
    end

    it 'is the first players turn' do
      expect(game.current_user).to be == user
    end
  end
end
