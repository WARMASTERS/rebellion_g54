require 'spec_helper'

require 'rebellion_g54/action/world_bank'

RSpec.describe RebellionG54::Action::WorldBank do
  let(:game) { example_game(2, roles: :world_bank) }
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  it 'includes coin count in description' do
    desc = game.choice_explanations(user)['world_bank'][:description]
    expect(desc).to include("0 coins")
  end

  context 'when using world bank with nothing in the bank' do
    before(:each) { game.take_choice(user, 'world_bank') }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
    end

    context 'when opponent passes' do
      let(:stream) { CollectingStream.new }

      before(:each) do
        game.output_streams << stream
        game.take_choice(opponent, 'pass')
      end

      it 'gives me 0 coins' do
        expect(game.user_coins(user)).to be == 2
      end

      it 'says how many coins it gave me' do
        expect(stream.messages).to be_any { |x| x.include?('0 coins') }
      end

      it 'ends my turn' do
        expect(game.current_user).to_not be == user
      end
    end
  end

  context 'when there are coins in the bank' do
    let!(:opponent) { game.users.last }

    before(:each) do
      game.take_choice(user, 'income')
      game.take_choice(opponent, 'income')
    end

    it 'includes coin count in description' do
      desc = game.choice_explanations(user)['world_bank'][:description]
      expect(desc).to include("2 coins")
    end
  end

  context 'when using world bank with coins in the bank' do
    let!(:opponent) { game.users.last }
    let(:stream) { CollectingStream.new }

    before(:each) do
      game.take_choice(user, 'income')
      game.take_choice(opponent, 'income')
      game.take_choice(user, 'world_bank')
      game.output_streams << stream
      game.take_choice(opponent, 'pass')
    end

    it 'gives me coins' do
      # One from income, two from banking.
      expect(game.user_coins(user)).to be == 5
    end

    it 'says how many coins it gave me' do
      expect(stream.messages).to be_any { |x| x.include?('2 coins') }
    end

    it 'ends my turn' do
      expect(game.current_user).to_not be == user
    end

    it 'does not give coins to another world banker' do
      game.take_choice(opponent, 'world_bank')
      game.take_choice(user, 'pass')
      expect(game.user_coins(opponent)).to be == 3
    end
  end

  context 'when using world bank with coins in the bank' do
    let(:roles) { [:director, :guerrilla] }
    let(:game) { example_game(2, roles: [:world_bank] + roles, rigged_roles: roles) }
    let!(:opponent) { game.users.last }

    before(:each) do
      game.take_choice(user, 'income')
      game.take_choice(opponent, 'income')
      game.take_choice(user, 'world_bank')
      game.take_choice(opponent, 'challenge')
      game.take_choice(user, 'show1')
    end

    it 'gives me no coins' do
      expect(game.user_coins(user)).to be == 3
    end

    it 'ends my turn' do
      expect(game.current_user).to_not be == user
    end

    it 'retains coins to give to another world banker' do
      game.take_choice(opponent, 'world_bank')
      game.take_choice(user, 'pass')
      expect(game.user_coins(opponent)).to be == 5
    end
  end
end
