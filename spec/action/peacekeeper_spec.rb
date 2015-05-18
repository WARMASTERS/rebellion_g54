require 'spec_helper'

require 'rebellion_g54/action/peacekeeper'

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
    @arguments = [player: {friendly: true}.freeze].freeze

    def resolve(game, token, active_player, join_players, target_players)
      target_players.each { |t| t.give_coins(token, 1) }
    end
  end
end; end

RSpec.describe RebellionG54::Action::Peacekeeper do
  let(:game) { example_game(2, coins: 7, roles: [:peacekeeper, :test_targetable, :test_friendly]) }
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using peacekeeper' do
    before(:each) { game.take_choice(user, 'peacekeeper') }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
    end

    context 'when opponent passes' do
      before(:each) { game.take_choice(opponent, 'pass') }

      it 'gives me a coin' do
        expect(game.user_coins(user)).to be == 8
      end

      it 'ends my turn' do
        expect(game.current_user).to_not be == user
      end

      it 'does not let opponent use test_targetable on me' do
        success, error = game.take_choice(opponent, 'test_targetable', user)
        expect(success).to be == false
        expect(error).to be =~ /peace/i
      end

      it 'lets opponent use coup on me' do
        success, _ = game.take_choice(opponent, 'coup', user)
        expect(success).to be == true
      end

      it 'lets opponent use friendly on me' do
        success, _ = game.take_choice(opponent, 'test_friendly', user)
        expect(success).to be == true
      end
    end
  end
end
