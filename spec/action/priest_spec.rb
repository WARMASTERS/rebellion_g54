require 'spec_helper'

require 'rebellion_g54/action/priest'

RSpec.describe RebellionG54::Action::Priest do
  let(:game) { example_game(3, roles: :priest) }

  it 'has alive players' do
    expect(game.each_player.map { |p| p }).to be_all(&:alive?)
  end

  context 'when using priest' do
    let(:users) { game.users }
    let!(:u1) { users[0] }
    let!(:u2) { users[1] }
    let!(:u3) { users[2] }

    before(:each) { game.take_choice(u1, 'priest') }

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

          it 'takes coins from opponents' do
            expect(game.user_coins(u2)).to be == 1
            expect(game.user_coins(u3)).to be == 1
          end

          it 'gives coins to me' do
            expect(game.user_coins(u1)).to be == 4
          end

          it 'ends my turn' do
            expect(game.current_user).to be == u2
          end
        end
      end
    end
  end
end
