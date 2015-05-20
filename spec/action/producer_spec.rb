require 'spec_helper'

require 'rebellion_g54/action/producer'

RSpec.describe RebellionG54::Action::Producer do
  let(:game) { example_game(2, roles: [:producer, :banker, :politician]) }
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using producer' do
    before(:each) do
      game.take_choice(user, 'producer', opponent)
      game.take_choice(opponent, 'pass')
    end

    it 'asks opponent for block decision' do
      expect(game.choice_names).to be == { opponent => ['block', 'pass'] }
    end

    context 'when opponent passes' do
      before(:each) { game.take_choice(opponent, 'pass') }

      it 'asks opponent for give decision' do
        expect(game.choice_names).to be == { opponent => ['give1', 'give2'] }
      end

      context 'when opponent picks card to give' do
        before(:each) { game.take_choice(opponent, 'give1') }

        it 'asks me for pick decision' do
          expect(game.choice_names).to be == { user => ['pick1', 'pick2', 'pick3', 'pick4'] }
        end

        it 'asks me to pick for myself' do
          expect(game.decision_description).to include('self')
        end

        context 'when I pick first card' do
          before(:each) { game.take_choice(user, 'pick1') }

          it 'asks me for pick decision' do
            expect(game.choice_names).to be == { user => ['pick1', 'pick2', 'pick3'] }
          end

          it 'asks me to pick for myself' do
            expect(game.decision_description).to include('self')
          end

          context 'when I pick second card' do
            before(:each) { game.take_choice(user, 'pick1') }

            it 'asks me for pick decision' do
              expect(game.choice_names).to be == { user => ['pick1', 'pick2'] }
            end

            it 'asks me to pick for opponent' do
              expect(game.decision_description).to include(opponent)
            end

            context 'when I pick for opponent' do
              before(:each) { game.take_choice(user, 'pick1') }

              it 'maintains my influence' do
                expect(game.user_influence(user)).to be == 2
              end

              it 'maintains opponent influence' do
                expect(game.user_influence(opponent)).to be == 2
              end

              it 'ends my turn' do
                expect(game.current_user).to_not be == user
              end
            end
          end
        end
      end
    end

    context 'when opponent blocks' do
      before(:each) do
        game.take_choice(opponent, 'block')
        game.take_choice(user, 'pass')
      end

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
  end
end
