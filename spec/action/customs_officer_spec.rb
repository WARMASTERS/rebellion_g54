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

      it 'gives me a tax token' do
        expect(game.player_tokens).to be == { user => [:tax] }
      end

      it 'gives the role a tax token' do
        expect(game.role_tokens).to be == { :customs_officer => [:tax] }
      end

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

    context 'on my turn' do
      before(:each) { game.take_choice(opponent, 'income') }

      it 'allows me to use customs officer' do
        expect(game.choice_names[user]).to include('customs_officer')
      end
    end
  end

  context 'when taxing player dies' do
    let(:game) { example_game(3, coins: 7, roles: :customs_officer) }
    let(:users) { game.users }
    let!(:u1) { users[0] }
    let!(:u2) { users[1] }
    let!(:u3) { users[2] }

    before(:each) do
      game.take_choice(u1, 'customs_officer', 'customs_officer')
      game.take_choice(u2, 'pass')
      game.take_choice(u3, 'pass')
      game.take_choice(u2, 'coup', u1)
      game.take_choice(u1, 'lose1')
      game.take_choice(u3, 'coup', u1)
    end

    it 'removes the player tax token' do
      expect(game.player_tokens).to be_empty
    end

    it 'removes the role tax token' do
      expect(game.role_tokens).to be_empty
    end
  end
end
