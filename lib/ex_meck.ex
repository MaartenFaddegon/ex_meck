defmodule ExMeck do
  @moduledoc """
  A mocking library particularly suitable for stateful property based testing.

  See test/ex_meck_test.ex for example usage.
  """

  @doc """
  Create a new mocked module.
  """
  def new(mod, opts \\ []), do: :meck.new(mod, opts)


  @doc """
  Stop mocking the module.
  """
  def unload(mod), do: :meck.unload(mod)

  @doc """
  Define a mocked function we expect to be called in the test.
  """
  def expect(mod, fun, expectation), do: :meck.expect(mod, fun, expectation)


  @doc """
  Verify wheter the history of the mocked module mod contains a call that satisfies specification spec.

  The specification is a nested tuple with the form {p, {m,f,a}, r} where
    p is the pid of the caller
    m is the module
    f is function
    a is a list of arguments
    r is the result.

  The atom :_ can be used as a don't care value.
  """
  def contains?(mod, spec, timeout \\ 1000)
  def contains?(_mod, _spec, timeout) when timeout <= 0, do: false
  def contains?(mod, spec, timeout) when timeout > 0 do
    history = :meck.history(mod)
    case Enum.any?(history, fn call -> matches? spec, call end) do
      true  -> true
      false -> :timer.sleep 100
               contains?(mod, spec, timeout - 100)
    end
  end

  @doc """
  As contains?/3 but returns {:error, :no_match} when no match was found or {:ok, match} with the match.

  This is useful when the match is used for further validation.
  """
  def contains(mod, spec, timeout \\ 1000)
  def contains(_mod, _spec, timeout) when timeout <= 0, do: {:error, :no_match}
  def contains(mod, spec, timeout) when timeout > 0 do
    history = :meck.history(mod)
    case Enum.filter(history, fn call -> matches? spec, call end) do
      [match|_]  -> {:ok, match}
      []         -> :timer.sleep 100
                    contains(mod, spec, timeout - 100)
    end
  end


  @doc """
  Reset the history of module mod.
  """
  def reset(mod), do: :meck.reset(mod)


  # The first argument (i.e. x and xs) is the specification, the specification may contain the atom :_ to indicate don't care
  # The second argument (i.e. y and ys) is tested against the specification

  defp matches?(xs,ys) when is_tuple(xs) and is_tuple(ys) do
    matches?(Tuple.to_list(xs), Tuple.to_list(ys))
  end
  defp matches?(xs,ys) when is_list(xs) and is_list(ys) do
    case length(xs) == length(ys) do
      true  -> z = Enum.zip(xs,ys)
               z2 = for {x,y} <- z, do: matches?(x,y)
               Enum.all?(z2)
      false -> false
    end
  end
  defp matches?(:_, _), do: 
    true
  defp matches?(x,y), do:
    x == y


end
