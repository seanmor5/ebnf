defmodule EBNF do
  @moduledoc """
  A simple EBNF Grammar parser using parser combinators.
  """

  alias EBNF.ParseState

  @end_of_alternate_marker 0
  @ref_rule_marker 1
  @literal_marker 2

  @doc """
  Parses an EBNF Grammar.
  """
  def parse(grammar) when is_binary(grammar) do
    EBNF.Parser.grammar(grammar)
  end

  @doc """
  Converts a grammar into an encoded ParseState.
  """
  def encode(grammar) do
    case parse(grammar) do
      {:ok, rules, "", _, _, _} ->
        traverse_rules(rules)

      _ ->
        raise "unable to parse grammar"
    end
  end

  defp traverse_rules(rules) do
    {grammar_encoding, symbol_ids} = Enum.flat_map_reduce(rules, %{}, &traverse_rule/2)
    %ParseState{symbol_ids: symbol_ids, grammar_encoding: grammar_encoding ++ [0xFFFF]}
  end

  defp traverse_rule({:rule, rule}, ids, root_name \\ nil) do
    case rule do
      [{:identifier, [name]} | sequences] ->
        root_name = root_name || name
        {rule_id, ids} = get_symbol_id(ids, name)
        {updated_rule, {encoding, ids}} = expand_rule(sequences, root_name, ids)
        {rule_encoding, ids} = traverse_sequences(updated_rule, ids)
        {encoding ++ [rule_id | rule_encoding] ++ [0], ids}

      rule ->
        raise "invalid rule #{inspect(rule)}"
    end
  end

  # We need to expand any groupings and repetitions into
  # their own rules, so we do a pass for that first
  defp expand_rule(sequences, name, ids) do
    Enum.map_reduce(sequences, {[], ids}, fn
      {:repetition, [{:grouping, sequences}, rep]}, {encoding, ids} ->
        # We need to expand groupings before expanding repetitions
        {inner_name, {group_encoding, ids}} = expand_grouping(sequences, ids, name)
        new_factor = {:identifier, [inner_name]}
        {rep_name, {rep_encoding, ids}} = expand_repetition(new_factor, rep, ids, name)
        {{:identifier, [rep_name]}, {encoding ++ group_encoding ++ rep_encoding, ids}}

      {:repetition, [factor, rep]}, {encoding, ids} ->
        {inner_name, {rule_encoding, ids}} = expand_repetition(factor, rep, ids, name)
        {{:identifier, [inner_name]}, {encoding ++ rule_encoding, ids}}

      {:grouping, sequences}, {encoding, ids} ->
        {inner_name, {rule_encoding, ids}} = expand_grouping(sequences, ids, name)
        {{:identifier, [inner_name]}, {encoding ++ rule_encoding, ids}}

      {:alternate, alternates}, {encoding, ids} ->
        {updated_sequence, {alternate_encoding, ids}} = expand_rule(alternates, name, ids)
        {{:alternate, updated_sequence}, {encoding ++ alternate_encoding, ids}}

      {:identifier, [name]}, {encoding, ids} ->
        {_id, ids} = get_symbol_id(ids, name)
        {{:identifier, [name]}, {encoding, ids}}

      term, acc ->
        {term, acc}
    end)
  end

  defp traverse_sequences([{:alternate, alternates}], ids) do
    alternates = group_alternates(alternates, [], [])

    Enum.flat_map_reduce(alternates, ids, fn sequence, ids ->
      traverse_sequences(sequence, ids)
    end)
  end

  defp traverse_sequences(sequences, ids) do
    {encoding, ids} = Enum.flat_map_reduce(sequences, ids, &traverse_sequence/2)
    {[length(encoding) + 1 | encoding] ++ [@end_of_alternate_marker], ids}
  end

  defp traverse_sequence(sequence, ids) do
    case sequence do
      {:terminal, terminal} ->
        {traverse_terminal(terminal), ids}

      {:identifier, [identifier]} ->
        {id, ids} = get_symbol_id(ids, identifier)
        {[@ref_rule_marker, id], ids}

      {:empty, []} ->
        {[], ids}
    end
  end

  defp traverse_terminal([{:string, chars}]) do
    Enum.flat_map(chars, fn codepoint -> [@literal_marker, codepoint, codepoint] end)
  end

  defp traverse_terminal([{:character_set, set}]) do
    set =
      Enum.flat_map(set, fn
        {:range, [{:char, [c1]}, {:char, [c2]}]} ->
          [c1, c2]

        {:char, [c]} ->
          [c, c]
      end)

    [length(set) | set]
  end

  defp group_alternates([], alternates, current_group) do
    Enum.reverse([Enum.reverse(current_group) | alternates])
  end

  defp group_alternates(["|" | rest], alternates, current_group) do
    group_alternates(rest, [Enum.reverse(current_group) | alternates], [])
  end

  defp group_alternates([factor | rest], alternates, current_group) do
    group_alternates(rest, alternates, [factor | current_group])
  end

  defp expand_repetition(factor, rep, ids, name) do
    next_symbol_id = map_size(ids)
    next_rule_name = "#{name}_#{next_symbol_id}"
    ids = Map.put(ids, next_rule_name, next_symbol_id)

    rule =
      case rep do
        "?" ->
          # S' ::= S |
          [alternate: [factor, "|", {:empty, []}]]

        "*" ->
          # S' ::= S S' |
          [alternate: [factor, {:identifier, [next_rule_name]}, "|", {:empty, []}]]

        "+" ->
          # S' ::= S S' | S
          [alternate: [factor, {:identifier, [next_rule_name]}, "|", factor]]
      end

    {next_rule_name, traverse_rule({:rule, [{:identifier, [next_rule_name]} | rule]}, ids, name)}
  end

  defp expand_grouping(sequences, ids, name) do
    next_symbol_id = map_size(ids)
    next_rule_name = "#{name}_#{next_symbol_id}"
    ids = Map.put(ids, next_rule_name, next_symbol_id)

    {next_rule_name,
     traverse_rule({:rule, [{:identifier, [next_rule_name]} | sequences]}, ids, name)}
  end

  defp get_symbol_id(ids, name) do
    case ids do
      %{^name => id} ->
        {id, ids}

      %{} ->
        id = map_size(ids)
        {id, Map.put(ids, name, id)}
    end
  end
end
