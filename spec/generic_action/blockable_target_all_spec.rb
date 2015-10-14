require 'spec_helper'

require 'rebellion_g54/action/base_target_all'

module RebellionG54; module Action
  class TestBlockableTargetAll < BaseTargetAll
    @flavor_name = 'Generic Blockable Target All'
    @description = '%s each lose 1 coin'
    @required_role = :test_blockable_target_all
    @blockable = true

    def resolve(game, token, active_player, join_players, target_players)
      target_players.each { |t| t.take_coins(token, 1) }
    end
  end

  class DummyRole < Base
  end
end; end

RSpec.describe RebellionG54::Action::TestBlockableTargetAll do
  let(:game) { example_game(3, coins: 8, roles: [:test_blockable_target_all, :dummy_role], rigged_roles: [:test_blockable_target_all, :dummy_role]) }
  let(:users) { game.users }
  let!(:u1) { users[0] }
  let!(:u2) { users[1] }
  let!(:u3) { users[2] }

  context 'when one opponent blocks and one does not' do
    before(:each) do
      game.take_choice(u1, 'test_blockable_target_all')
      # Pass on challenge of u1 action
      game.take_choice(u2, 'pass')
      game.take_choice(u3, 'pass')
      # u2 passes on block, u3 blocks
      game.take_choice(u2, 'pass')
      game.take_choice(u3, 'block')
      # Pass on challenge of u3 block
      game.take_choice(u1, 'pass')
      game.take_choice(u2, 'pass')
    end

    it 'affects non-blocking opponent' do
      expect(game.user_coins(u2)).to be == 7
    end

    it 'does not affect blocking opponent' do
      expect(game.user_coins(u3)).to be == 8
    end

    it 'ends my turn' do
      expect(game.current_user).to_not be == u1
    end
  end

  context 'when being eliminated while using with only one influence' do
    before(:each) do
      game.take_choice(u1, 'coup', u2)
      game.take_choice(u2, 'lose2')
      game.take_choice(u2, 'test_blockable_target_all')
      # Pass on challenge of u2 action
      game.take_choice(u3, 'pass')
      game.take_choice(u1, 'pass')
      # u3 blocks
      game.take_choice(u3, 'block')
      # u1 passes on challenge, u2 challenges
      game.take_choice(u1, 'pass')
      game.take_choice(u2, 'challenge')
      # u3 shows correct role
      game.take_choice(u3, 'show1')
      # at this point u2 should be eliminated.
    end

    it 'eliminates the user' do
      expect(game.size).to be == 2
    end

    it 'still asks remaining player to block or pass' do
      expect(game.choice_names).to include({ u1 => ['block', 'pass'] })
    end

    context 'when remaining player declines block' do
      before(:each) { game.take_choice(u1, 'pass') }

      it 'still affects the non-blocking player' do
        expect(game.user_coins(u1)).to be == 0
      end

      it 'does not skip a player in turn order' do
        expect(game.current_user).to be == u3
      end
    end
  end
end
