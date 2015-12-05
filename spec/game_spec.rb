require 'spec_helper'

require 'rebellion_g54/game'

RSpec.describe RebellionG54::Game do
  context 'basic 2p game' do
    subject { example_game(2) }
    let(:user) { subject.choice_names.keys.first }

    it 'cannot be started again' do
      expect { subject.start_game(%w(p1 p2)) }.to raise_exception(StandardError)
    end

    it 'has players' do
      expect(subject.size).to be == 2
    end

    it 'has alive players' do
      expect(subject.each_player.map { |p| p }).to be_all(&:alive?)
    end

    it 'has players with 2 influence' do
      expect(subject.each_player.map { |p| p }).to be_all { |p| p.influence == 2 }
    end

    it 'has a turn number' do
      expect(subject.turn_number).to be == 1
    end

    it 'has a decision description' do
      expect(subject.decision_description).to be =~ /#{user}.*turn/
    end

    it 'has choice explanations' do
      expect(subject.choice_explanations(user)).to_not be_empty
    end

    it 'does not let me make a bogus action' do
      success, error = subject.take_choice(user, 'invalid!!!')
      expect(success).to be == false
      # Eh, "not valid" or "invalid" should be good enough.
      expect(error).to be =~ /(not.*|in)valid/
    end
  end

  context 'in a game with synchronous challenges' do
    subject { example_game(
      3, synchronous_challenges: true, roles: [:banker, :director], rigged_roles: [:director, :banker]
    ) }
    let(:users) { subject.users }
    let!(:u1) { users[0] }
    let!(:u2) { users[1] }
    let!(:u3) { users[2] }

    before(:each) { subject.take_choice(u1, 'banker') }

    it 'asks only u2 for challenge decision' do
      expect(subject.choice_names).to be == { u2 => ['challenge', 'pass'] }
    end

    context 'when u2 passes' do
      before(:each) { subject.take_choice(u2, 'pass') }

      it 'asks u3 for challenge decision' do
        expect(subject.choice_names).to be == { u3 => ['challenge', 'pass'] }
      end
    end

    context 'when u2 challenges' do
      before(:each) do
        subject.take_choice(u2, 'challenge')
        subject.take_choice(u1, 'show1')
      end

      # Wanting to make sure it doesn't make u3 also challenge.

      it 'ends the turn' do
        expect(subject.current_user).to be == u2
      end
    end
  end

  context 'in a game with asynchronous challenges' do
    subject { example_game(
      3, synchronous_challenges: false, roles: [:banker, :director], rigged_roles: [:director, :banker]
    ) }
    let(:users) { subject.users }
    let!(:u1) { users[0] }
    let!(:u2) { users[1] }
    let!(:u3) { users[2] }

    before(:each) { subject.take_choice(u1, 'banker') }

    it 'asks both opponents for challenge decision' do
      expect(subject.choice_names).to be == {
        u2 => ['challenge', 'pass'],
        u3 => ['challenge', 'pass'],
      }
    end

    context 'when u2 challenges' do
      before(:each) do
        subject.take_choice(u2, 'challenge')
        subject.take_choice(u1, 'show1')
      end

      it 'ends the turn' do
        expect(subject.current_user).to be == u2
      end
    end

    context 'when u3 challenges' do
      before(:each) do
        subject.take_choice(u3, 'challenge')
        subject.take_choice(u1, 'show1')
      end

      it 'ends the turn' do
        expect(subject.current_user).to be == u2
      end
    end

    context 'when u2 then u3 pass' do
      before(:each) do
        subject.take_choice(u2, 'pass')
        subject.take_choice(u3, 'pass')
      end

      it 'ends the turn' do
        expect(subject.current_user).to be == u2
      end
    end

    context 'when u3 then u2 pass' do
      before(:each) do
        subject.take_choice(u3, 'pass')
        subject.take_choice(u2, 'pass')
      end

      it 'ends the turn' do
        expect(subject.current_user).to be == u2
      end
    end
  end

  context 'wrong number of roles' do
    subject { RebellionG54::Game.new('testgame') }
    before(:each) do
      subject.roles = [:banker, :director, :guerilla, :politician]
    end

    it 'does not start the game' do
      success, error = subject.start_game(%w(p1 p2))
      expect(success).to be == false
      expect(error).to include('5')
    end
  end

  context 'invalid role' do
    subject { RebellionG54::Game.new('testgame') }
    before(:each) do
      subject.roles = [:banker, :director, :guerilla, :politician, :cheese_grater]
    end

    it 'does not start the game' do
      success, error = subject.start_game(%w(p1 p2))
      expect(success).to be == false
      expect(error).to include('invalid')
    end
  end

  context 'replacing a player' do
    subject { RebellionG54::Game.new('testgame') }
    before(:each) do
      subject.start_game(['p1', 'p3'])
      subject.replace_player('p1', 'p2')
    end

    it 'does not consider p1 to be in the game' do
      expect(subject.users).to_not include('p1')
    end

    it 'considers p1 to be in the game' do
      expect(subject.users).to include('p2')
    end

    it 'does not change player count' do
      expect(subject.size).to be == 2
    end
  end
end
