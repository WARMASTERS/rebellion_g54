require 'spec_helper'

require 'rebellion_g54/action/general'

RSpec.describe RebellionG54::Action::General do
  let(:game) { example_game(3, coins: 5, roles: :general) }

  it 'has players with 2 influence' do
    expect(game.each_player.map { |p| p }).to be_all { |p| p.influence == 2 }
  end

  context 'when using general' do
    let(:users) { game.users }
    let!(:u1) { users[0] }
    let!(:u2) { users[1] }
    let!(:u3) { users[2] }

    before(:each) { game.take_choice(u1, 'general') }

    it 'asks opponents for challenge decision' do
      expect(game.choice_names).to include({ u2 => ['challenge', 'pass'] })
    end

    context 'when opponents pass' do
      before(:each) {
        game.take_choice(u2, 'pass')
        game.take_choice(u3, 'pass')
      }

      it 'asks opponent for block decision' do
        expect(game.choice_names).to be == { u2 => ['block', 'pass'] }
      end

      context 'when opponent passes' do
        before(:each) { game.take_choice(u2, 'pass') }

        it 'asks other opponent for block decision' do
          expect(game.choice_names).to be == { u3 => ['block', 'pass'] }
        end

        context 'when other opponent passes' do
          before(:each) { game.take_choice(u3, 'pass') }

          it 'asks first opponent for lose decision' do
            expect(game.choice_names).to be == { u2 => ['lose1', 'lose2'] }
          end

          context 'when first opponent loses card' do
            before(:each) { game.take_choice(u2, 'lose1') }

            it 'asks second opponent for lose decision' do
              expect(game.choice_names).to be == { u3 => ['lose1', 'lose2'] }
            end

            context 'when second opponent loses card' do
              before(:each) { game.take_choice(u3, 'lose1') }

              it 'takes my coins' do
                expect(game.user_coins(u1)).to be == 0
              end

              it 'ends my turn' do
                expect(game.current_user).to be == u2
              end
            end
          end
        end
      end
    end
  end
end
