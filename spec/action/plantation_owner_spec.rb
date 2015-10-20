require 'spec_helper'

require 'rebellion_g54/action/plantation_owner'

RSpec.describe RebellionG54::Action::PlantationOwner do
  let(:game) { example_game(3, roles: :plantation_owner) }

  context 'when using plantation owner' do
    let(:users) { game.users }
    let!(:u1) { users[0] }
    let!(:u2) { users[1] }
    let!(:u3) { users[2] }

    before(:each) do
      # This is mostly tested in the joinables test and I got lazy
      game.take_choice(u1, 'plantation_owner')
      # pass on challenges
      game.take_choice(u2, 'pass')
      game.take_choice(u3, 'pass')
      # u2 joins, u3 does not (delayed challenges, remember)
      game.take_choice(u2, 'join')
      game.take_choice(u3, 'pass')
      # u1 and u3 do not challenge u2
      game.take_choice(u1, 'pass')
      game.take_choice(u3, 'pass')
    end

    it 'gave me coins' do
      expect(game.user_coins(u1)).to be == 5
    end

    it 'gave joiner coins' do
      expect(game.user_coins(u2)).to be == 4
    end

    it 'did not give non-joiner coins' do
      expect(game.user_coins(u3)).to be == 2
    end

    it 'ends my turn' do
      expect(game.current_user).to be == u2
    end
  end
end
