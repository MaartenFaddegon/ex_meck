defmodule Timer do
  def send_after(ms, msg) do
    tref = :erlang.send_after(ms, self(), msg)
    {tref, msg}
  end

  def cancel_timer({tref,msg}) do
    case :erlang.cancel_timer(tref) do
      false -> receive do
                 m when m == msg -> :ok
                end
      _ms   -> :ok
    end
  end
end
