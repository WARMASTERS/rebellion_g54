require 'spec_helper'

require 'rebellion_g54/action/base_single_target'

module RebellionG54; module Action
  class TestBlockable < BaseSingleTarget
    @flavor_name = 'Generic Blockable'
    @description = 'Gain 1 coin, make %s lose 1 coin'
    @required_role = :test_blockable
    @blockable = true

    def resolve(game, token, active_player, join_players, target_players)
      active_player.give_coins(token, 1)
      target_players.each { |t| t.take_coins(token, 1) }
    end
  end

  class DummyRole < Base
  end
end; end

RSpec.describe RebellionG54::Action::TestBlockable do
  let(:game) { example_game(2, roles: [:test_blockable, :dummy_role], rigged_roles: [:test_blockable, :dummy_role]) }
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using test_blockable' do
    before(:each) { game.take_choice(user, 'test_blockable', opponent) }

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

          it 'asks opponent for block decision' do
            expect(game.choice_names).to be == { opponent => ['block', 'pass'] }
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

      it 'asks opponent for block decision' do
        expect(game.choice_names).to be == { opponent => ['block', 'pass'] }
      end

      context 'when opponent blocks' do
        before(:each) { game.take_choice(opponent, 'block') }

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
                expect(game.user_coins(user)).to be == 3
              end

              it 'does not take opponent coins' do
                expect(game.user_coins(opponent)).to be == 2
              end

              it 'ends my turn' do
                expect(game.current_user).to_not be == user
              end
            end
          end

          context 'when showing wrong card' do
            before(:each) { game.take_choice(opponent, 'show2') }

            it 'gives me coins' do
              expect(game.user_coins(user)).to be == 3
            end

            it 'takes opponent coins' do
              expect(game.user_coins(opponent)).to be == 1
            end

            it 'ends my turn' do
              expect(game.current_user).to_not be == user
            end
          end
        end

        context 'when I pass' do
          before(:each) { game.take_choice(user, 'pass') }

          it 'gives me coins' do
            expect(game.user_coins(user)).to be == 3
          end

          it 'does not take opponent coins' do
            expect(game.user_coins(opponent)).to be == 2
          end

          it 'ends my turn' do
            expect(game.current_user).to_not be == user
          end
        end
      end

      context 'when opponent passes' do
        before(:each) { game.take_choice(opponent, 'pass') }

        it 'gives me coins' do
          expect(game.user_coins(user)).to be == 3
        end

        it 'takes opponent coins' do
          expect(game.user_coins(opponent)).to be == 1
        end

        it 'ends my turn' do
          expect(game.current_user).to_not be == user
        end
      end
    end
  end
end
