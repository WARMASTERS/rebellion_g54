require 'spec_helper'

require 'rebellion_g54/action/socialist'

RSpec.describe RebellionG54::Action::Socialist do
  let(:users) { game.users }
  let!(:u1) { users[0] }
  let!(:u2) { users[1] }
  let!(:u3) { users[2] }

  context 'when using socialist' do
    let(:game) { example_game(3, roles: :socialist) }
    before(:each) { game.take_choice(u1, 'socialist') }

    it 'asks opponents for challenge decision' do
      expect(game.choice_names.values).to be_all { |v| v == ['challenge', 'pass'] }
    end

    context 'when opponents pass on challenge' do
      before(:each) do
        game.take_choice(u2, 'pass')
        game.take_choice(u3, 'pass')
      end

      it 'asks first opponent for give decision' do
        expect(game.choice_names).to be == { u2 => ['give1', 'give2', 'pay'] }
      end

      context 'when first opponent gives card' do
        before(:each) { game.take_choice(u2, 'give1') }

        it 'asks second opponent for give decision' do
          expect(game.choice_names).to be == { u3 => ['give1', 'give2', 'pay'] }
        end

        context 'when second opponent gives card' do
          before(:each) { game.take_choice(u3, 'give1') }

          it 'asks me to add a card' do
            expect(game.choice_names).to be == { u1 => ['add1', 'add2'] }
          end

          context 'when I add a card' do
            before(:each) { game.take_choice(u1, 'add1') }

            it 'asks me for pick decision' do
              expect(game.choice_names).to be == { u1 => ['pick1', 'pick2', 'pick3'] }
            end

            context 'when I pick a card to keep' do
              before(:each) { game.take_choice(u1, 'pick1') }

              it 'maintains my influence' do
                expect(game.user_influence(u1)).to be == 2
              end

              it 'maintains opponent influence' do
                expect(game.user_influence(u2)).to be == 2
                expect(game.user_influence(u3)).to be == 2
              end

              it 'ends my turn' do
                expect(game.current_user).to_not be == u1
              end
            end
          end
        end
      end

      context 'when first opponent pays' do
        before(:each) { game.take_choice(u2, 'pay') }

        it 'asks second opponent for give decision' do
          expect(game.choice_names).to be == { u3 => ['give1', 'give2', 'pay'] }
        end

        context 'when second opponent pays' do
          before(:each) { game.take_choice(u3, 'pay') }

          it 'maintains my influence' do
            expect(game.user_influence(u1)).to be == 2
          end

          it 'maintains opponent influence' do
            expect(game.user_influence(u2)).to be == 2
            expect(game.user_influence(u3)).to be == 2
          end

          it 'gives me coins' do
            expect(game.user_coins(u1)).to be == 4
          end

          it 'takes opponent coins' do
            expect(game.user_coins(u2)).to be == 1
            expect(game.user_coins(u3)).to be == 1
          end

          it 'ends my turn' do
            expect(game.current_user).to_not be == u1
          end
        end
      end
    end
  end

  context 'when opponents are broke' do
    let(:game) { example_game(3, roles: :socialist, coins: 0) }
    before(:each) do
      game.take_choice(u1, 'socialist')
      game.take_choice(u2, 'pass')
      game.take_choice(u3, 'pass')
    end

    it 'does not allow paying' do
      expect(game.choice_names).to be == { u2 => ['give1', 'give2'] }
    end
  end
end
