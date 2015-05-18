require 'spec_helper'

require 'rebellion_g54/action/customs_officer'

module RebellionG54; module Action
  class DummyRole < Base
  end
end; end

RSpec.describe RebellionG54::Action::CustomsOfficer do
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using customs officer' do
    let(:game) { example_game(2, roles: [:customs_officer, :dummy_role]) }

    before(:each) { game.take_choice(user, 'customs_officer', 'customs_officer') }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
    end

    context 'when opponent passes' do
      before(:each) { game.take_choice(opponent, 'pass') }

      it 'ends my turn' do
        expect(game.current_user).to_not be == user
      end

      context 'when opponent claims customs officer' do
        before(:each) { game.take_choice(opponent, 'customs_officer', 'customs_officer') }

        it 'gives me a coin' do
          expect(game.user_coins(user)).to be == 3
        end

        it 'takes a coin from opponent' do
          expect(game.user_coins(opponent)).to be == 1
        end
      end
    end
  end

  context 'when cannot afford tax' do
    # I need the dummy role otherwise opponent might be forced to do income by auto-complete
    # (This would never happen in a real game; there would be roles availble)
    let(:game) { example_game(2, coins: 0, roles: [:customs_officer, :dummy_role]) }

    before(:each) do
      game.take_choice(user, 'customs_officer', 'customs_officer')
      game.take_choice(opponent, 'pass')
    end

    it 'ends my turn' do
      expect(game.current_user).to be == opponent
    end

    it 'does not allow opponent to use customs officer' do
      expect(game.choice_names[opponent]).to_not include('customs_officer')
    end
  end
end
