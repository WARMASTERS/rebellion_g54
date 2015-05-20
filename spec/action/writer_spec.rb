require 'spec_helper'

require 'rebellion_g54/action/writer'

RSpec.describe RebellionG54::Action::Writer do
  let(:game) { example_game(2, roles: [:writer, :banker, :politician]) }
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using writer' do
    before(:each) { game.take_choice(user, 'writer') }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
    end

    context 'when opponent passes' do
      before(:each) { game.take_choice(opponent, 'pass') }

      it 'asks me for draw decision' do
        expect(game.choice_names).to be == { user => ['draw', 'pass'] }
      end

      context 'when I pass' do
        before(:each) { game.take_choice(user, 'pass') }

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

            it 'maintains my influence' do
              expect(game.user_influence(user)).to be == 2
            end

            it 'ends my turn' do
              expect(game.current_user).to_not be == user
            end
          end
        end
      end

      context 'when I draw' do
        before(:each) { game.take_choice(user, 'draw') }

        it 'asks me for draw decision' do
          expect(game.choice_names).to be == { user => ['draw', 'pass'] }
        end

        context 'when I pass' do
          before(:each) { game.take_choice(user, 'pass') }

          it 'asks me for pick decision' do
            expect(game.choice_names).to be == { user => ['pick1', 'pick2', 'pick3', 'pick4'] }
          end

          it 'takes a coin' do
            expect(game.user_coins(user)).to be == 1
          end

          context 'when I pick my cards' do
            before(:each) { 2.times { game.take_choice(user, 'pick1') } }

            it 'maintains my influence' do
              expect(game.user_influence(user)).to be == 2
            end

            it 'ends my turn' do
              expect(game.current_user).to_not be == user
            end
          end
        end

        context 'when I draw' do
          before(:each) { game.take_choice(user, 'draw') }

          it 'takes a coin' do
            expect(game.user_coins(user)).to be == 0
          end
          # OK, auto-complete should pick pass since I have no money now...

          it 'asks me for pick decision' do
            expect(game.choice_names).to be == { user => ['pick1', 'pick2', 'pick3', 'pick4', 'pick5'] }
          end

          context 'when I pick my cards' do
            before(:each) { 2.times { game.take_choice(user, 'pick1') } }

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
end
