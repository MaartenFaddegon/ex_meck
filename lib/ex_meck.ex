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
  Stop all mocked modules.
  """
  def unload(), do: :meck.unload()

  @doc """
  Stop mocking the module.
  """
  def unload(mod), do: :meck.unload(mod)

  @doc """
  Define a mocked function we expect to be called in the test.
  """
  def expect(mod, fun, expectation), do: :meck.expect(mod, fun, expectation)

  @doc """
  Deletes the expectation created with expect/3
  """
  def delete(mod, fun, arity), do: :meck.delete(mod, fun, arity)

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

  def contains?(m, {_p, {_m, f, a}, _r} = spec, timeout \\ 1000, times \\ 1) do
    try do
      :ok = :meck.wait(times, m, f, a, timeout)

      history = :meck.history(m)

      case Enum.filter(history, fn(call) -> matches?(spec, call) end) do
        [_match|_]  -> true
        []          -> false
      end
    catch :error, :timeout ->
      false
    end
  end

  @doc """
  As contains?/3 but returns {:error, :no_match} when no match was found or {:ok, match} with the match.

  This is useful when the match is used for further validation.
  """
  def contains(m, {_p, {_m, f, a}, _r} = spec, timeout \\ 1000, times \\ 1) do
    try do
      :ok = :meck.wait(times, m, f, a, timeout)
      history = :meck.history(m)
      case Enum.filter(history, fn(call) -> matches?(spec, call) end) do
        [match|_]  -> {:ok, match}
        []         -> {:error, :no_match}
      end
    catch :error, :timeout -> {:error, :no_match}
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
