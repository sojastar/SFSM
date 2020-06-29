require           'minitest/autorun'
require_relative  'test_helper.rb'

describe FSM::State do
  it 'initializes' do
    state = FSM::State.new(:a_state) { puts "do nothing" }

    assert_equal  :a_state,     state.name

    assert_nil                  state.setup
    assert_empty                state.events
  end

  it 'stores a setup proc for the parent object' do
    state   = FSM::State.new(:a_state) do
      define_setup do
        instance_variable_set :@test_variable, 1234
      end
    end

    parent  = Object.new
    parent.instance_eval  &state.setup

    assert_equal  1234, parent.instance_variable_get(:@test_variable)
  end

  it 'stores events checking procs' do
    state   = FSM::State.new(:a_state) do
      add_event(next_state: :another_state) do |args|
        args == :go_to_another_state
      end

      add_event(next_state: :yet_another_state) do |args|
        args == :go_to_yet_another_state
      end
    end

    parent  = Object.new    # dummy

    refute  parent.instance_exec(:go_somewhere,             &state.events[0][:check])
    refute  parent.instance_exec(:go_to_yet_another_state,  &state.events[0][:check])
    assert  parent.instance_exec(:go_to_another_state,      &state.events[0][:check])

    refute  parent.instance_exec(:go_somewhere,             &state.events[1][:check])
    refute  parent.instance_exec(:go_to_another_state,      &state.events[1][:check])
    assert  parent.instance_exec(:go_to_yet_another_state,  &state.events[1][:check])
  end

  it 'updates' do
    state = FSM::State.new(:a_state) do
      define_setup do
        instance_variable_set :@test_variable, 1234
      end

      add_event(next_state: :another_state) do |args|
        args[:v] == @test_variable            &&
        args[:n] == :go_to_another_state
      end

      add_event(next_state: :yet_another_state) do |args|
        args[:v] == @test_variable            &&
        args[:n] == :go_to_yet_another_state
      end
    end

    parent  = Object.new
    parent.instance_eval &state.setup

    assert_equal  :a_state,           state.update(parent, { v: 1235, n: :some_state } )
    assert_equal  :another_state,     state.update(parent, { v: 1234, n: :go_to_another_state } )
    assert_equal  :yet_another_state, state.update(parent, { v: 1234, n: :go_to_yet_another_state } )
  end
end
