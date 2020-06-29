require           'minitest/autorun'
require_relative  'test_helper.rb'

describe FSM::Machine do
  it 'initializes' do
    parent  = Object.new
    machine = FSM::Machine.new(parent) { puts "do nothing" }

    assert_equal  parent,   machine.parent
    assert_equal  Hash.new, machine.states
    assert_nil              machine.current_state
  end

  it 'can add a new state and set it as the initial state' do
    parent  = Object.new
    machine = FSM::Machine.new(parent) do
      add_state :new_state do
        define_setup do
          instance_variable_set :@test_variable, 1234
        end

        add_event(next_state: :another_state) do |args|
          args[:v] == :@test_variable           &&
          args[:n] == :go_to_another_state 
        end

        add_event(next_state: :yet_another_state) do |args|
          args[:v] == :@test_variable           &&
          args[:n] == :go_to_yet_another_state 
        end
      end

      set_initial_state :new_state
    end

    assert                        machine.states.has_key? :new_state
    assert_equal  1234,           parent.instance_variable_get(:@test_variable) # proper setup of the parent ...
                                                                                # ... with the first state setup block
    assert_equal  :new_state,     machine.current_state
  end

  it 'can update' do
    parent  = Object.new
    machine = FSM::Machine.new(parent) do
      add_state :a_state do
        define_setup do
          instance_variable_set :@test_variable, 1234
        end

        add_event(next_state: :another_state) do |args|
          args[:v] == @test_variable            &&
          args[:n] == :go_to_another_state 
        end
      end

      add_state :another_state do
        define_setup do
          instance_variable_set :@test_variable, 5678
        end

        add_event(next_state: :yet_another_state) do |args|
          args[:v] == @test_variable            &&
          args[:n] == :go_to_yet_another_state 
        end
      end

      set_initial_state :a_state
    end

    machine.update( { v: 1235, n: :somewhere_else } )
    assert_equal  :a_state, machine.current_state

    machine.update( { v: 1234, n: :go_to_another_state } )
    assert_equal  :another_state, machine.current_state
    assert_equal  5678, parent.instance_variable_get(:@test_variable)
  end
end
