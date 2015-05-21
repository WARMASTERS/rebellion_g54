require 'spec_helper'

require 'rebellion_g54/action/base_target_all'

module RebellionG54; module Action
  class TestTargetAll < BaseTargetAll
    @flavor_name = 'Generic Target All'
    @description = '%s each lose 1 coin'
    @required_role = :test_target_all

    def resolve(game, token, active_player, join_players, target_players)
      target_players.each { |t| t.take_coins(token, 1) }
    end
  end

  class DummyRole < Base
  end
end; end

RSpec.describe RebellionG54::Action::TestTargetAll do
  let(:game) { example_game(3, roles: [:test_target_all, :dummy_role], rigged_roles: [:test_target_all, :dummy_role]) }
  let(:users) { game.users }
  let!(:u1) { users[0] }
  let!(:u2) { users[1] }
  let!(:u3) { users[2] }

  context 'when using test_target_all' do
    before(:each) { game.take_choice(u1, 'test_target_all') }

    it 'asks opponents for challenge decision' do
      expect(game.choice_names).to include({ u2 => ['challenge', 'pass'] })
    end

    context 'when opponent passes' do
      before(:each) {
        game.take_choice(u2, 'pass')
        game.take_choice(u3, 'pass')
      }

      it 'takes opponent coins' do
        expect(game.user_coins(u2)).to be == 1
        expect(game.user_coins(u3)).to be == 1
      end

      it 'ends my turn' do
        expect(game.current_user).to_not be == u1
      end
    end
  end

  context 'when targeting a treatied player' do
    before(:each) do
      # This is bad. Don't do this at home.
      token = game.instance_variable_get(:@action_token)
      game.set_treaty(token, game.find_player(u1), game.find_player(u2))
      game.take_choice(u1, 'test_target_all')
      game.take_choice(u2, 'pass')
      game.take_choice(u3, 'pass')
    end

    it 'takes untreatied opponent coins' do
      expect(game.user_coins(u3)).to be == 1
    end

    it 'does not take treatied opponent coins' do
      expect(game.user_coins(u2)).to be == 2
    end

    it 'ends my turn' do
      expect(game.current_user).to_not be == u1
    end
  end

  context 'when targeting players in an unrelated treaty ' do
    before(:each) do
      # This is bad. Don't do this at home.
      token = game.instance_variable_get(:@action_token)
      game.set_treaty(token, game.find_player(u2), game.find_player(u3))
      game.take_choice(u1, 'test_target_all')
      game.take_choice(u2, 'pass')
      game.take_choice(u3, 'pass')
    end

    it 'takes both opponent coins' do
      expect(game.user_coins(u2)).to be == 1
      expect(game.user_coins(u3)).to be == 1
    end

    it 'ends my turn' do
      expect(game.current_user).to_not be == u1
    end
  end

  context 'when targeting a peaced player' do
    before(:each) do
      # This is bad. Don't do this at home.
      token = game.instance_variable_get(:@action_token)
      game.set_peace(token, game.find_player(u2))
      game.take_choice(u1, 'test_target_all')
      game.take_choice(u2, 'pass')
      game.take_choice(u3, 'pass')
    end

    it 'takes unpeaced opponent coins' do
      expect(game.user_coins(u3)).to be == 1
    end

    it 'does not take peaced opponent coins' do
      expect(game.user_coins(u2)).to be == 2
    end

    it 'ends my turn' do
      expect(game.current_user).to_not be == u1
    end
  end
end
