require 'spec_helper'

require 'rebellion_g54/action/anarchist'

RSpec.describe RebellionG54::Action::Anarchist do
  let(:roles) { [:anarchist, :banker] }
  let(:game) { example_game(3, coins: 3, roles: roles, rigged_roles: roles) }
  let(:users) { game.users }
  let!(:u1) { users[0] }
  let!(:u2) { users[1] }
  let!(:u3) { users[2] }

  context 'when using anarchist' do
    before(:each) { game.take_choice(u1, 'anarchist', u2) }

    it 'asks bomb target for bomb decision' do
      expect(game.choice_names).to be == { u2 => ["bomb#{u3}", 'defuse', 'pass'] }
    end

    context 'when bomb target passes' do
      before(:each) { game.take_choice(u2, 'pass') }

      it 'asks bomb target for lose decision' do
        expect(game.choice_names).to be == { u2 => ['lose1', 'lose2'] }
      end

      context 'when bomb target loses influence' do
        before(:each) { game.take_choice(u2, 'lose1') }

        it 'takes my coins' do
          expect(game.user_coins(u1)).to be == 0
        end

        it 'ends my turn' do
          expect(game.current_user).to_not be == u1
        end
      end
    end

    context 'when bomb target defuses' do
      before(:each) { game.take_choice(u2, 'defuse') }

      it 'asks for challenge decision' do
        expect(game.choice_names.values).to be_all { |v| v == ['challenge', 'pass'] }
      end

      context 'when everyone passes on challenging defuse' do
        before(:each) do
          game.take_choice(u1, 'pass')
          game.take_choice(u3, 'pass')
        end

        it 'takes my coins' do
          expect(game.user_coins(u1)).to be == 0
        end

        it 'ends my turn' do
          expect(game.current_user).to_not be == u1
        end
      end

      context 'on a challenge where target is lying' do
        before(:each) do
          game.take_choice(u1, 'challenge')
          game.take_choice(u2, 'show2')
          # auto decision should knock u2 out.
        end

        it 'eliminates target' do
          expect(game.find_player(u2)).to be_nil
          expect(game.find_dead_player(u2)).to_not be_nil
        end

        it 'ends my turn' do
          expect(game.current_user).to_not be == u1
        end
      end

      context 'on a challenge where target is truthful' do
        before(:each) do
          game.take_choice(u1, 'challenge')
          game.take_choice(u2, 'show1')
          game.take_choice(u1, 'lose1')
        end

        it 'takes my coins' do
          expect(game.user_coins(u1)).to be == 0
        end

        it 'ends my turn' do
          expect(game.current_user).to_not be == u1
        end
      end
    end

    context 'when bomb target moves bomb' do
      before(:each) { game.take_choice(u2, "bomb#{u3}") }

      it 'asks for challenge decision' do
        expect(game.choice_names.values).to be_all { |v| v == ['challenge', 'pass'] }
      end

      context 'when everyone passes on challenging move' do
        before(:each) do
          game.take_choice(u1, 'pass')
          game.take_choice(u3, 'pass')
        end

        it 'asks new bomb target for bomb decision' do
          expect(game.choice_names).to be == { u3 => ['defuse', 'pass'] }
        end

        # Going to assume defuse and pass work the same for this new player.
      end

      context 'on a challenge where target is lying' do
        before(:each) do
          game.take_choice(u1, 'challenge')
          game.take_choice(u2, 'show2')
          # auto decision should knock u2 out.
        end

        it 'eliminates target' do
          expect(game.find_player(u2)).to be_nil
          expect(game.find_dead_player(u2)).to_not be_nil
        end

        it 'ends my turn' do
          expect(game.current_user).to_not be == u1
        end
      end

      context 'on a challenge where target is truthful' do
        before(:each) do
          game.take_choice(u1, 'challenge')
          game.take_choice(u2, 'show1')
          game.take_choice(u1, 'lose1')
        end

        it 'asks new bomb target for bomb decision' do
          expect(game.choice_names).to be == { u3 => ['defuse', 'pass'] }
        end
      end
    end
  end
end
