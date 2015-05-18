require 'spec_helper'

require 'rebellion_g54/action/base'

module RebellionG54; module Action
  class TestJoinableWithRole < Base
    @flavor_name = 'Generic Joinable with role'
    @description = 'Gain 2 coin, 1 coin to those who join'
    @required_role = :test_joinable_with_role
    @joinable = true
    @join_requires_role = true

    def resolve(game, token, active_player, join_players, target_players)
      active_player.give_coins(token, 2)
      join_players.each { |j| j.give_coins(token, 1) }
    end
  end

  class Test2 < Base
  end
end; end

RSpec.describe RebellionG54::Action::TestJoinableWithRole do
  let(:game) { example_game(2, roles: [:test_joinable_with_role, :dummy_role], rigged_roles: [:test_joinable_with_role, :dummy_role]) }
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using test_joinable_with_role' do
    before(:each) { game.take_choice(user, 'test_joinable_with_role', opponent) }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
    end

    context 'when opponent challenges' do
      before(:each) { game.take_choice(opponent, 'challenge') }

      it 'asks me for show decision' do
        expect(game.choice_names).to be == { user => ['show1', 'show2'] }
      end

      context 'when showing right card' do
        before(:each) { game.take_choice(user, 'show1') }

        it 'asks opponent for lose decision' do
          expect(game.choice_names).to be == { opponent => ['lose1', 'lose2'] }
        end

        context 'when opponent flips' do
          before(:each) { game.take_choice(opponent, 'lose1') }

          # Going to assume that the rest works the same.

          it 'asks opponent for join decision' do
            expect(game.choice_names).to be == { opponent => ['join', 'pass'] }
          end
        end
      end

      context 'when showing wrong card' do
        before(:each) { game.take_choice(user, 'show2') }

        it 'gives me no coins' do
          expect(game.user_coins(user)).to be == 2
        end

        it 'decreases my influence' do
          expect(game.user_influence(user)).to be == 1
        end

        it 'ends my turn' do
          expect(game.current_user).to_not be == user
        end
      end
    end

    context 'when opponent passes' do
      before(:each) { game.take_choice(opponent, 'pass') }

      it 'asks opponent for join decision' do
        expect(game.choice_names).to be == { opponent => ['join', 'pass'] }
      end

      context 'when opponent joins' do
        before(:each) { game.take_choice(opponent, 'join') }

        it 'asks me for challenge decision' do
          expect(game.choice_names).to be == { user => ['challenge', 'pass'] }
        end

        context 'when I challenge' do
          before(:each) { game.take_choice(user, 'challenge') }

          it 'asks opponent for show decision' do
            expect(game.choice_names).to be == { opponent => ['show1', 'show2'] }
          end

          context 'when showing right card' do
            before(:each) { game.take_choice(opponent, 'show1') }

            it 'asks me for lose decision' do
              expect(game.choice_names).to be == { user => ['lose1', 'lose2'] }
            end

            context 'when I flip' do
              before(:each) { game.take_choice(user, 'lose1') }

              it 'gives me coins' do
                expect(game.user_coins(user)).to be == 4
              end

              it 'gives opponent coins' do
                expect(game.user_coins(opponent)).to be == 3
              end

              it 'ends my turn' do
                expect(game.current_user).to_not be == user
              end
            end
          end

          context 'when showing wrong card' do
            before(:each) { game.take_choice(opponent, 'show2') }

            it 'gives me coins' do
              expect(game.user_coins(user)).to be == 4
            end

            it 'does not give opponent coins' do
              expect(game.user_coins(opponent)).to be == 2
            end

            it 'ends my turn' do
              expect(game.current_user).to_not be == user
            end
          end
        end

        context 'when I pass' do
          before(:each) { game.take_choice(user, 'pass') }

          it 'gives me coins' do
            expect(game.user_coins(user)).to be == 4
          end

          it 'gives opponent coins' do
            expect(game.user_coins(opponent)).to be == 3
          end

          it 'ends my turn' do
            expect(game.current_user).to_not be == user
          end
        end
      end

      context 'when opponent passes' do
        before(:each) { game.take_choice(opponent, 'pass') }

        it 'gives me coins' do
          expect(game.user_coins(user)).to be == 4
        end

        it 'does not give opponent coins' do
          expect(game.user_coins(opponent)).to be == 2
        end

        it 'ends my turn' do
          expect(game.current_user).to_not be == user
        end
      end
    end
  end
end
