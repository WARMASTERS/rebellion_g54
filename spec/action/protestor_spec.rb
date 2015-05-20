require 'spec_helper'

require 'rebellion_g54/action/protestor'

RSpec.describe RebellionG54::Action::Protestor do
  let(:game) { example_game(3, coins: 3, roles: :protestor) }

  it 'has players with 2 influence' do
    expect(game.each_player.map { |p| p }).to be_all { |p| p.influence == 2 }
  end

  context 'when using protestor' do
    let(:users) { game.users }
    let!(:u1) { users[0] }
    let!(:u2) { users[1] }
    let!(:u3) { users[2] }

    before(:each) { game.take_choice(u1, 'protestor', u2) }

    it 'asks opponents for challenge decision' do
      expect(game.choice_names).to be == {
        u2 => ['challenge', 'pass'],
        u3 => ['challenge', 'pass'],
      }
    end

    context 'when opponents pass' do
      before(:each) do
        game.take_choice(u2, 'pass')
        game.take_choice(u3, 'pass')
      end

      it 'asks non-targeted opponent for join decision' do
        expect(game.choice_names).to be == { u3 => ['join', 'pass'] }
      end

      context 'when opponent passes' do
        before(:each) { game.take_choice(u3, 'pass') }

        it 'takes my coins' do
          expect(game.user_coins(u1)).to be == 1
        end

        it 'does not take joiner coins' do
          expect(game.user_coins(u3)).to be == 3
        end

        it 'ends my turn' do
          expect(game.current_user).to be == u2
        end

        it 'does not decrease target influence' do
          expect(game.user_influence(u2)).to be == 2
        end
      end

      context 'when opponent joins' do
        before(:each) { game.take_choice(u3, 'join') }

        it 'asks target for block decision' do
          expect(game.choice_names).to be == { u2 => ['block', 'pass'] }
        end

        context 'when target blocks' do
          before(:each) do
            game.take_choice(u2, 'block')
            # Assuming the results of a challenged block are tested elsewhere.
            game.take_choice(u1, 'pass')
            game.take_choice(u3, 'pass')
          end

          it 'takes my coins' do
            expect(game.user_coins(u1)).to be == 1
          end

          it 'takes joiner coins' do
            expect(game.user_coins(u3)).to be == 0
          end

          it 'ends my turn' do
            expect(game.current_user).to be == u2
          end

          it 'does not decrease target influence' do
            expect(game.user_influence(u2)).to be == 2
          end
        end

        context 'when target passes' do
          before(:each) { game.take_choice(u2, 'pass') }

          it 'asks target for lose decision' do
            expect(game.choice_names).to be == { u2 => ['lose1', 'lose2'] }
          end

          context 'when target loses a card' do
            before(:each) { game.take_choice(u2, 'lose1') }

            it 'takes my coins' do
              expect(game.user_coins(u1)).to be == 1
            end

            it 'takes joiner coins' do
              expect(game.user_coins(u3)).to be == 0
            end

            it 'ends my turn' do
              expect(game.current_user).to be == u2
            end

            it 'decreases target influence' do
              expect(game.user_influence(u2)).to be == 1
            end
          end
        end
      end
    end
  end
end
