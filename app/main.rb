require 'lib/fsm_state.rb'
require 'lib/fsm_machine.rb'





# ---=== CONSTANTS : ===---
JUMP_STRENGTH = 10
GRAVITY       = -1





# ---=== PLAYER CLASS ===---
class Player
  attr_reader :y, :glyph

  def initialize(&machine_config_block)
    @dy       = 0
    @y        = 0

    @side     = :right
    @glyph    = '-'

    @machine  = FSM::new_machine(self, &machine_config_block)
  end

  def update(args)
    @machine.update( { input: args.inputs.keyboard, and_other_stuff: 'any other stuff you want' } )

    if @machine.current_state == :jumping then
      @y   += @dy
      @dy  += GRAVITY
    end
  end

  def state
    @machine.current_state
  end
end





# ---=== SETUP : ===---
def setup(args)
  args.state.player = Player.new() do
                        # IDLE STATE :
                        add_state :idle do
                          define_setup do
                            @glyph  = '|'
                          end

                          add_event(next_state: :walking) do |args|
                            if args[:input].key_held.left then
                              @side = :left
                              true

                            elsif args[:input].key_held.right then
                              @side = :right
                              true

                            else
                              false

                            end
                          end

                          add_event(next_state: :jumping) do |args|
                            args[:input].key_held.space
                          end
                        end

                        # WALKING STATE :
                        add_state :walking do
                          define_setup do
                            @glyph  = ( @side == :right ? '>' : '<' )
                          end

                          add_event(next_state: :idle) do |args|
                            !args[:input].key_held.left && !args[:input].key_held.right
                          end

                          add_event(next_state: :jumping) do |args|
                            args[:input].key_held.space
                          end
                        end

                        # JUMPING STATE :
                        add_state :jumping do
                          define_setup do
                            @dy     = JUMP_STRENGTH
                            @glyph  = '^'
                          end

                          add_event(next_state: :idle) do |args|
                            if @y < 0 then
                              @dy, @y = 0, 0
                              true
                            else
                              false
                            end
                          end
                        end

                        set_initial_state :idle
                      end

  args.state.setup_done = true
end





# ---=== MAIN LOOP : ===---
def tick(args)
  setup(args) unless args.state.setup_done

  args.state.player.update(args)

  args.outputs.labels << [ 20, 700, "player state: #{args.state.player.state}" ]
  args.outputs.labels << [ 20, 680, "player y: #{args.state.player.y}" ]
  args.outputs.labels << [ 610, 300 + args.state.player.y, args.state.player.glyph ]
end
