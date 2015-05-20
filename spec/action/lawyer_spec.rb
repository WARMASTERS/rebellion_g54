require 'spec_helper'

require 'rebellion_g54/action/lawyer'

module RebellionG54; module Action
  class DummyRole < Base
  end
end; end

RSpec.describe RebellionG54::Action::Lawyer do
  let(:game) { example_game(3, coins: 7, roles: [:lawyer, :dummy_role], rigged_roles: [:lawyer, :dummy_role]) }
  let(:users) { game.users }
  let!(:u1) { users[0] }
  let!(:u2) { users[1] }
  let!(:u3) { users[2] }

  it 'has alive players' do
    expect(game.each_player.map { |p| p }).to be_all(&:alive?)
  end

  it 'does not allow use of lawyer' do
    expect(game.choice_names[u1]).to_not include('lawyer')
  end

  context 'on death' do
    before(:each) do
      game.take_choice(u1, 'coup', u3)
      game.take_choice(u3, 'lose1')
      game.take_choice(u2, 'coup', u3)
      # auto-complete should do lose1 for u3
    end

    it 'asks u2 for lawyer decision' do
      expect(game.choice_names).to be == { u2 => ['lawyer', 'pass'] }
    end

    context 'when both players pass' do
      before (:each) do
        game.take_choice(u2, 'pass')
        game.take_choice(u1, 'pass')
      end

      it 'ends the turn' do
        expect(game.current_user).to be == u1
      end

      it 'gives nobody money' do
        expect(game.user_coins(u1)).to be == 0
        expect(game.user_coins(u2)).to be == 0
      end
    end

    context 'when both players claim' do
      before(:each) do
        game.take_choice(u2, 'lawyer')
        game.take_choice(u1, 'pass')
        game.take_choice(u1, 'lawyer')
      end

      it 'asks u2 for challenge decision' do
        expect(game.choice_names).to be == { u2 => ['challenge', 'pass'] }
      end

      context 'when u2 challenges' do
        before(:each) { game.take_choice(u2, 'challenge') }

        it 'asks u1 for show decision' do
          expect(game.choice_names).to be == { u1 => ['show1', 'show2'] }
        end

        context 'when u1 shows right card' do
          before(:each) { game.take_choice(u1, 'show1') }

          it 'asks u2 for lose decision' do
            expect(game.choice_names).to be == { u2 => ['lose1', 'lose2'] }
          end

          context 'when u2 loses a card' do
            before(:each) { game.take_choice(u2, 'lose1') }

            it 'ends the turn' do
              expect(game.current_user).to be == u1
            end

            it 'gives both players money' do
              expect(game.user_coins(u1)).to be == 3
              expect(game.user_coins(u2)).to be == 3
            end
          end
        end

        context 'when u1 shows wrong card' do
          before(:each) { game.take_choice(u1, 'show2') }

          it 'decreases u1 influence' do
            expect(game.user_influence(u1)).to be == 1
          end

          it 'gives u2 money' do
            expect(game.user_coins(u2)).to be == 7
          end

          it 'does not give u1 money' do
            expect(game.user_coins(u1)).to be == 0
          end

          it 'ends the turn' do
            expect(game.current_user).to be == u1
          end
        end
      end

      context 'when u2 passes' do
        before(:each) { game.take_choice(u2, 'pass') }

        it 'ends the turn' do
          expect(game.current_user).to be == u1
        end

        it 'gives both players money' do
          expect(game.user_coins(u1)).to be == 3
          expect(game.user_coins(u2)).to be == 3
        end
      end
    end

    context 'when u2 claims' do
      before(:each) { game.take_choice(u2, 'lawyer') }

      it 'asks u1 for challenge decision' do
        expect(game.choice_names).to be == { u1 => ['challenge', 'pass'] }
      end

      # Got lazy. Assuming the rest works out the same.
    end
  end
end
