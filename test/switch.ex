defmodule Switch do
  use GenStateMachine, callback_mode: :state_functions

  def start(ip) do
    GenStateMachine.start(Switch, [ip], name: Switch)
  end

  def stop() do
    GenStateMachine.stop(Switch)
  end

  def flip() do
    GenStateMachine.cast(Switch, :flip)
  end

  def init([ip]) do
    s = :gen_udp.open(4001, [:binary, {:active, :true}])
    {:ok, :off, %{socket: s, ip: ip, tref: :undefined}}
  end

  def off(:cast, :flip, data = %{socket: s, ip: ip}), do:
    {:next_state, :switching_on, %{data | tref: switch(s, ip, <<1>>)}}

  def switching_on(:info, :timedout, data = %{socket: s, ip: ip}), do:
    {:next_state, :switching_on, %{data | tref: switch(s, ip, <<1>>)}}
  def switching_on(:info, {:udp, _socket, _address, _port, <<1>>}, data = %{tref: t}) do
    Timer.cancel_timer(t)
    {:next_state, :on, data}
  end
  def switching_on(:cast, :flip, _data), do:
    :keep_state_and_data

  def on(:cast, :flip, data = %{socket: s, ip: ip}), do:
    {:next_state, :switching_off, %{data | tref: switch(s, ip, <<0>>)}}

  def switching_off(:info, :timedout, data = %{socket: s, ip: ip}), do:
    {:next_state, :switching_off, %{data | tref: switch(s, ip, <<0>>)}}
  def switching_off(:info, {:udp, _socket, _address, _port, <<0>>}, data = %{tref: t}) do
    Timer.cancel_timer(t)
    {:next_state, :off, data}
  end
  def switching_off(:cast, :flip, _data), do:
    :keep_state_and_data

  defp switch(s, ip, msg) do
    :gen_udp.send(s, ip, 4000, msg)
    Timer.send_after(1000, :timedout)
  end
end
