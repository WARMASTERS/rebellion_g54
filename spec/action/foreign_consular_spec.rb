require 'spec_helper'

require 'rebellion_g54/action/foreign_consular'

module RebellionG54; module Action
  class TestTargetable < BaseSingleTarget
    @flavor_name = 'Generic Targetable'
    @description = 'Make %s lose 1 coin'
    @required_role = :test_targetable
    @blockable = true

    def resolve(game, token, active_player, join_players, target_players)
      target_players.each { |t| t.take_coins(token, 1) }
    end
  end

  class TestFriendly < BaseSingleTarget
    @flavor_name = 'Generic Friendly'
    @description = 'Make %s gain 1 coin'
    @required_role = :test_friendly
    @arguments = [{type: :player, friendly: true}.freeze].freeze

    def resolve(game, token, active_player, join_players, target_players)
      target_players.each { |t| t.give_coins(token, 1) }
    end
  end
end; end

RSpec.describe RebellionG54::Action::ForeignConsular do
  let(:game) { example_game(3, coins: 7, roles: [:foreign_consular, :test_targetable, :test_friendly]) }

  context 'when using foreign_consular' do
    let(:users) { game.users }
    let!(:u1) { users[0] }
    let!(:u2) { users[1] }
    let!(:u3) { users[2] }

    before(:each) do
      game.take_choice(u1, 'foreign_consular', u2)
      game.take_choice(u2, 'pass')
      game.take_choice(u3, 'pass')
    end

    it 'shows the treaty token' do
      expect(game.player_tokens).to be == { u1 => [:treaty], u2 => [:treaty] }
    end

    it 'ends my turn' do
      expect(game.current_user).to be == u2
    end

    context 'for opponent under the treaty' do
      it 'does not let opponent use test_targetable on me' do
        success, error = game.take_choice(u2, 'test_targetable', u1)
        expect(success).to be == false
        expect(error).to be =~ /treaty/i
      end

      it 'does not let opponent use coup on me' do
        success, error = game.take_choice(u2, 'coup', u1)
        expect(success).to be == false
        expect(error).to be =~ /treaty/i
      end

      it 'lets opponent use friendly on me' do
        success, _ = game.take_choice(u2, 'test_friendly', u1)
        expect(success).to be == true
      end
    end

    context 'for opponent not under the treaty' do
      before(:each) { game.take_choice(u2, 'income') }

      it 'lets opponent use test_targetable on me' do
        success, _ = game.take_choice(u3, 'test_targetable', u1)
        expect(success).to be == true
      end

      it 'lets opponent use coup on me' do
        success, _ = game.take_choice(u3, 'coup', u1)
        expect(success).to be == true
      end

      it 'lets opponent use friendly on me' do
        success, _ = game.take_choice(u3, 'test_friendly', u1)
        expect(success).to be == true
      end
    end
  end
end
