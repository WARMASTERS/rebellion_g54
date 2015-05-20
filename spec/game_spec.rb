require 'spec_helper'

require 'rebellion_g54/game'

RSpec.describe RebellionG54::Game do
  context 'basic 2p game' do
    subject { example_game(2) }
    let(:user) { subject.choice_names.keys.first }

    it 'cannot be started again' do
      expect { subject.start_game }.to raise_exception
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

  context 'wrong number of roles' do
    subject { RebellionG54::Game.new('testgame') }
    before(:each) do
      subject.roles = [:banker, :director, :guerilla, :politician]
    end

    it 'does not start the game' do
      success, error = subject.start_game
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
      success, error = subject.start_game
      expect(success).to be == false
      expect(error).to include('invalid')
    end
  end

  context 'removing a player' do
    subject { RebellionG54::Game.new('testgame') }
    before(:each) do
      subject.add_player('p1')
      subject.remove_player('p1')
    end

    it 'does not consider p1 to be in the game' do
      expect(subject.has_player?('p1')).to be == false
    end

    it 'has no players' do
      expect(subject.size).to be == 0
    end
  end

  context 'replacing a player' do
    subject { RebellionG54::Game.new('testgame') }
    before(:each) do
      subject.add_player('p1')
      subject.replace_player('p1', 'p2')
    end

    it 'does not consider p1 to be in the game' do
      expect(subject.has_player?('p1')).to be == false
    end

    it 'considers p1 to be in the game' do
      expect(subject.has_player?('p2')).to be == true
    end

    it 'has one player' do
      expect(subject.size).to be == 1
    end
  end
end
