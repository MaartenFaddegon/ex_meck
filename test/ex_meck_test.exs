defmodule ExMeckTest do
  use ExUnit.Case
  use PropCheck
  use PropCheck.StateM

  def initial_state, do: :off

  def command(state) when state == :on or state == :off, do: 
    {:call, Switch, :flip, []}
  def command(:switching_off), do: 
    frequency([
      {1, {:call, :erlang, :send, [Switch, {:udp, :dummy_socket, :dummy_address, :dummy_port, <<0>>}]}},
      {3, {:call, :erlang, :send, [Switch, :timedout]}}
    ])
  def command(:switching_on), do: 
    frequency([
      {1, {:call, :erlang, :send, [Switch, {:udp, :dummy_socket, :dummy_address, :dummy_port, <<1>>}]}},
      {3, {:call, :erlang, :send, [Switch, :timedout]}}
    ])

  def next_state(:off, _result, {:call, Switch, :flip, []}), do:
    :switching_on
  def next_state(:on, _result, {:call, Switch, :flip, []}), do:
    :switching_off
  def next_state(:switching_on, _result, {:call, :erlang, :send, [Switch, {:udp, :dummy_socket, :dummy_address, :dummy_port, <<1>>}]}), do:
    :on
  def next_state(:switching_off, _result,  {:call, :erlang, :send, [Switch, {:udp, :dummy_socket, :dummy_address, :dummy_port, <<0>>}]}), do:
   :off
  def next_state(state, _result, {:call, :erlang, :send, [Switch, :timedout]}), do:
    state

  def precondition(state, {:call, Switch, :flip, []}), do:
    state == :off or state == :on
  def precondition(state, {:call, :erlang, :send, [Switch, {:udp, :dummy_socket, :dummy_address, :dummy_port, <<1>>}]}), do:
    state == :switching_off
  def precondition(state,  {:call, :erlang, :send, [Switch, {:udp, :dummy_socket, :dummy_address, :dummy_port, <<0>>}]}), do:
    state == :switching_off
  def precondition(state, {:call, :erlang, :send, [Switch, :timedout]}), do:
    state == :switching_on or state == :switching_off

  def postcondition(state, {:call, Switch, :flip, []}, _result) do
    msg = case state do
            :off  -> <<1>>
            :on -> <<0>>
          end
    pduSent  = ExMeck.contains? :gen_udp, {:_, {:gen_udp, :send, [:_, :_, :_, msg]}, :_}
    timerSet = ExMeck.contains? Timer, {:_, {Timer, :send_after, [:_, :timedout]}, :_}
    exMeckReset()
    pduSent and timerSet
  end
  def postcondition(_state, _call, _result) do 
    exMeckReset()
    true
  end

  property "stateful property with mocking" do
    numtests(100, forall cmds <- commands(__MODULE__) do
      exMeckInit()
      Switch.start({1,2,3,4})
      {history, state, result} = run_commands(__MODULE__, cmds)
      Switch.stop()
      exMeckUnload()
      (result == :ok)
        |> aggregate(command_names cmds)
        |> when_fail(IO.puts """
                             History: #{inspect history, pretty: true}
                             State: #{inspect state, pretty: true}
                             Result: #{inspect result, pretty: true}
                             """)
    end)
  end

  def exMeckInit() do
    ExMeck.new(Timer)
    ExMeck.expect(Timer, :send_after, fn(_a, _b) -> {:ok, :dummyTref} end)
    ExMeck.new(:gen_udp, [:unstick])
    ExMeck.expect(:gen_udp, :open, fn(_a,_b) -> {:ok, :dummySocket} end)
    ExMeck.expect(:gen_udp, :send, fn(_a,_b,_c,_d) -> :ok end)
  end

  def exMeckUnload() do
    :meck.unload(Timer)
    :meck.unload(:gen_udp)
    Code.load_file("test/timer.ex")
  end

  def exMeckReset do
    ExMeck.reset :gen_udp
    ExMeck.reset Timer
  end

end
