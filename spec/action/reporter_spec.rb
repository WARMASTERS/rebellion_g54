require 'spec_helper'

require 'rebellion_g54/action/reporter'

RSpec.describe RebellionG54::Action::Reporter do
  let(:game) { example_game(2, roles: [:reporter, :banker, :politician]) }
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using reporter' do
    before(:each) { game.take_choice(user, 'reporter') }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
    end

    context 'when opponent passes' do
      before(:each) { game.take_choice(opponent, 'pass') }

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

          it 'gives me a coin' do
            expect(game.user_coins(user)).to be == 3
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
end
