defmodule EBNF.Parser.Helpers do
  import NimbleParsec

  def repeatable(combinator) do
    choice([
      tag(concat(combinator, choice([string("*"), string("+"), string("?")])), :repetition),
      combinator
    ])
  end
end
