require 'spec_helper'

require 'rebellion_g54/action/mercenary'

RSpec.describe RebellionG54::Action::Mercenary do
  let(:user) { game.choice_names.keys.first }
  let(:opponent) { game.users.last }

  context 'when using mercenary' do
    let(:game) { example_game(2, coins: 3, rigged_roles: [:mercenary, :banker], roles: [:mercenary, :banker]) }
    before(:each) { game.take_choice(user, 'mercenary', opponent) }

    it 'asks opponent for challenge decision' do
      expect(game.choice_names).to be == { opponent => ['challenge', 'pass'] }
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

        context 'when I pass' do
          before(:each) { game.take_choice(user, 'pass') }

          it 'takes my coins' do
            expect(game.user_coins(user)).to be == 0
          end

          it 'ends my turn' do
            expect(game.current_user).to_not be == user
          end
        end
      end

      context 'when opponent passes' do
        before(:each) { game.take_choice(opponent, 'pass') }

        it 'takes my coins' do
          expect(game.user_coins(user)).to be == 0
        end

        it 'ends my turn' do
          expect(game.current_user).to_not be == user
        end

        it 'does not decrease opponent influence' do
          expect(game.user_influence(opponent)).to be == 2
        end

        it 'asks opponent to block' do
          expect(game.choice_names.keys).to be == [opponent]
          expect(game.choice_names[opponent]).to include('block')
          expect(game.choice_names[opponent]).to include('income')
        end

        context 'when opponent blocks at start of turn' do
          before(:each) { game.take_choice(opponent, 'block') }

          it 'asks me for challenge decision' do
            expect(game.choice_names).to be == { user => ['challenge', 'pass'] }
          end

          context 'when I challenge' do
            before(:each) { game.take_choice(user, 'challenge') }

            it 'asks opponent for show decision' do
              expect(game.choice_names).to be == { opponent => ['show1', 'show2'] }
            end

            context 'when showing the right card' do
              before(:each) do
                game.take_choice(opponent, 'show1')
                game.take_choice(user, 'lose1')
              end

              it 'continues opponent turn' do
                expect(game.current_user).to be == opponent
                expect(game.choice_names.keys).to be == [opponent]
                expect(game.choice_names[opponent]).to include('income')
              end

              it 'does not require opponent to block again' do
                expect(game.choice_names.keys).to be == [opponent]
                expect(game.choice_names[opponent]).to_not include('block')
              end
            end

            context 'when showing the wrong card' do
              before(:each) { game.take_choice(opponent, 'show2') }

              it 'decreases opponent influence' do
                expect(game.user_influence(opponent)).to be == 1
              end
            end
          end

          context 'when I pass' do
            before(:each) { game.take_choice(user, 'pass') }

            it 'continues opponent turn' do
              expect(game.current_user).to be == opponent
              expect(game.choice_names.keys).to be == [opponent]
              expect(game.choice_names[opponent]).to include('income')
            end

            it 'does not require opponent to block again' do
              expect(game.choice_names.keys).to be == [opponent]
              expect(game.choice_names[opponent]).to_not include('block')
            end
          end
        end

        context 'when opponent does something other than blocking' do
          before(:each) { game.take_choice(opponent, 'income') }

          it 'asks opponent for lose decision' do
            expect(game.choice_names).to be == { opponent => ['lose1', 'lose2', 'mercenary'] }
          end

          context 'when opponent blocks at end of turn' do
            before(:each) { game.take_choice(opponent, 'mercenary') }

            it 'asks me for challenge decision' do
              expect(game.choice_names).to be == { user => ['challenge', 'pass'] }
            end

            context 'when I challenge' do
              before(:each) { game.take_choice(user, 'challenge') }

              it 'asks opponent for show decision' do
                expect(game.choice_names).to be == { opponent => ['show1', 'show2'] }
              end

              context 'when showing the right card' do
                before(:each) do
                  game.take_choice(opponent, 'show1')
                  game.take_choice(user, 'lose1')
                end

                it 'ends opponent turn' do
                  expect(game.current_user).to_not be == opponent
                end

                it 'does not decrease opponent influence' do
                  expect(game.user_influence(opponent)).to be == 2
                end
              end

              context 'when showing the wrong card' do
                before(:each) { game.take_choice(opponent, 'show2') }

                it 'eliminates opponent' do
                  expect(game.find_player(opponent)).to be_nil
                  expect(game.find_dead_player(opponent)).to_not be_nil
                end
              end
            end

            context 'when I pass' do
              before(:each) { game.take_choice(user, 'pass') }

              it 'ends opponent turn' do
                expect(game.current_user).to_not be == opponent
              end

              it 'does not decrease opponent influence' do
                expect(game.user_influence(opponent)).to be == 2
              end
            end
          end
        end
      end
    end
  end
end
