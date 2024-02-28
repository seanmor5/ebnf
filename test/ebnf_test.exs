defmodule EBNFTest do
  use ExUnit.Case

  alias EBNF.ParseState

  doctest EBNF

  describe "parse/1" do
    test "simple" do
      grammar = fixture("simple.gbnf")
      assert {:ok, _parsed, "", _, _, _} = EBNF.parse(grammar)
    end

    test "character set" do
      grammar = fixture("char_set.gbnf")
      assert {:ok, _parsed, "", _, _, _} = EBNF.parse(grammar)
    end

    test "string" do
      grammar = fixture("string.gbnf")
      assert {:ok, _parsed, "", _, _, _} = EBNF.parse(grammar)
    end

    test "choice" do
      grammar = fixture("choice.gbnf")
      assert {:ok, _parsed, "", _, _, _} = EBNF.parse(grammar)
    end

    test "optional" do
      grammar = fixture("optional.gbnf")
      assert {:ok, _parsed, "", _, _, _} = EBNF.parse(grammar)
    end

    test "repetitions" do
      grammar = fixture("repetitions.gbnf")
      assert {:ok, _parsed, "", _, _, _} = EBNF.parse(grammar)
    end

    test "concatenation" do
      grammar = fixture("concatenation.gbnf")
      assert {:ok, _parsed, "", _, _, _} = EBNF.parse(grammar)
    end

    test "simple arithmetic" do
      grammar = fixture("simple_arithmetic.gbnf")
      assert {:ok, _parsed, "", _, _, _} = EBNF.parse(grammar)
    end

    test "json" do
      grammar = fixture("json.gbnf")
      assert {:ok, _parsed, "", _, _, _} = EBNF.parse(grammar)
    end
  end

  describe "encode/1" do
    test "simple" do
      grammar = fixture("simple.gbnf")

      assert %ParseState{symbol_ids: %{"root" => 0}, grammar_encoding: encoded} =
               EBNF.encode(grammar)

      assert encoded == [0, 13, 2, 116, 116, 2, 114, 114, 2, 117, 117, 2, 101, 101, 0, 0, 65535]
    end

    test "optional" do
      grammar = fixture("optional.gbnf")

      %ParseState{symbol_ids: %{"optional" => 0}, grammar_encoding: encoded} =
        EBNF.encode(grammar)

      assert encoded ==
               [0, 16, 2, 109, 109, 2, 97, 97, 2, 121, 121] ++
                 [2, 98, 98, 2, 101, 101, 0, 1, 0, 0, 65535]
    end

    test "optional expansion" do
      grammar = fixture("optional_expansion.gbnf")

      %ParseState{symbol_ids: %{"optional" => 0}, grammar_encoding: encoded} =
        EBNF.encode(grammar)

      assert encoded ==
               [1, 16, 2, 109, 109, 2, 97, 97, 2, 121, 121, 2, 98, 98] ++
                 [2, 101, 101, 0, 1, 0, 0, 0, 3, 1, 1, 0, 0, 65535]
    end

    test "character set" do
      grammar = fixture("char_set.gbnf")

      assert %ParseState{symbol_ids: %{"root" => 0}, grammar_encoding: encoded} =
               EBNF.encode(grammar)

      assert encoded == [0, 12, 10, 97, 122, 65, 65, 66, 66, 67, 67, 43, 43, 0, 0, 65535]
    end

    test "charset with escapes" do
      grammar = fixture("charset_with_escapes.gbnf")

      assert %ParseState{
               symbol_ids: %{"ws" => 0},
               grammar_encoding: encoded
             } = EBNF.encode(grammar)

      assert encoded == [0, 8, 6, 32, 32, 9, 9, 10, 10, 0, 0, 65535]
    end

    test "string with escapes" do
      grammar = fixture("string_escape.gbnf")

      assert %ParseState{symbol_ids: %{"newline" => 0}, grammar_encoding: encoded} =
               EBNF.encode(grammar)

      assert encoded == [0, 4, 2, 10, 10, 0, 0, 65535]
    end

    test "concatenation" do
      grammar = fixture("concatenation.gbnf")

      assert %ParseState{symbol_ids: %{"root" => 0}, grammar_encoding: encoded} =
               EBNF.encode(grammar)

      assert encoded == [0, 10, 2, 91, 91, 2, 97, 122, 2, 93, 93, 0, 0, 65535]
    end

    test "choice" do
      grammar = fixture("choice.gbnf")

      assert %ParseState{symbol_ids: %{"root" => 0, "false" => 1}, grammar_encoding: encoded} =
               EBNF.encode(grammar)

      assert encoded ==
               [0, 3, 1, 1, 0, 13, 2, 116, 116, 2, 114, 114, 2, 117, 117, 2] ++
                 [101, 101, 0, 4, 2, 97, 122, 0, 0, 1, 16, 2, 102, 102, 2, 97] ++
                 [97, 2, 108, 108, 2, 115, 115, 2, 101, 101, 0, 0, 65535]
    end

    test "choice concatenation" do
      grammar = fixture("choice_concat.gbnf")

      %ParseState{symbol_ids: %{"term" => 0}, grammar_encoding: encoded} = EBNF.encode(grammar)

      assert encoded ==
               [0, 4, 2, 48, 57, 0, 20, 2, 40, 40, 2, 97, 122] ++
                 [2, 48, 57, 2, 41, 41, 6, 32, 32, 9, 9, 10, 10, 0, 0, 65535]
    end

    test "zero or more" do
      grammar = fixture("zero_or_more.gbnf")

      assert %ParseState{
               symbol_ids: %{"zero_or_more" => 0, "zero_or_more_1" => 1},
               grammar_encoding: encoded
             } = EBNF.encode(grammar)

      assert encoded ==
               [1, 15, 2, 122, 122, 2, 101, 101, 2, 114, 114, 2] ++
                 [111, 111, 1, 1, 0, 1, 0, 0, 0, 3, 1, 1, 0, 0, 65535]
    end

    test "one or more" do
      grammar = fixture("one_or_more.gbnf")

      assert %ParseState{
               symbol_ids: %{"one_or_more" => 0, "one_or_more_1" => 1},
               grammar_encoding: encoded
             } = EBNF.encode(grammar)

      assert encoded ==
               [1, 12, 2, 111, 111, 2, 110, 110, 2, 101, 101, 1, 1] ++
                 [0, 10, 2, 111, 111, 2, 110, 110, 2, 101, 101, 0] ++
                 [0, 0, 3, 1, 1, 0, 0, 65535]
    end

    test "alternates expansion" do
      grammar = fixture("alternates_repetition.gbnf")

      assert %ParseState{
               symbol_ids: %{"root" => 0, "root_1" => 1, "root_2" => 2},
               grammar_encoding: encoded
             } = EBNF.encode(grammar)

      assert encoded ==
               [1, 12, 2, 111, 111, 2, 110, 110, 2, 101, 101, 1, 1] ++
                 [0, 1, 0, 0, 2, 12, 2, 116, 116, 2, 119, 119, 2] ++
                 [111, 111, 1, 2, 0, 10, 2, 116, 116, 2, 119, 119] ++
                 [2, 111, 111, 0, 0, 0, 3, 1, 1, 0, 3, 1, 2, 0, 4] ++
                 [2, 97, 122, 0, 0, 65535]
    end

    test "grouping expansion" do
      grammar = fixture("grouping.gbnf")

      assert %ParseState{
               symbol_ids: %{"root" => 0, "root_1" => 1, "root_2" => 2},
               grammar_encoding: encoded
             } = EBNF.encode(grammar)

      assert encoded ==
               [1, 13, 2, 116, 116, 2, 114, 114, 2, 117, 117, 2, 101, 101] ++
                 [0, 16, 2, 102, 102, 2, 97, 97, 2, 108, 108, 2, 115, 115] ++
                 [2, 101, 101, 0, 0, 2, 6, 2, 97, 122, 1, 2, 0, 1, 0, 0, 0] ++
                 [5, 1, 1, 1, 2, 0, 0, 65535]
    end

    test "grouped repetition" do
      grammar = fixture("grouped_repetition.gbnf")

      assert %ParseState{
               symbol_ids: %{"root" => 0, "root_1" => 1, "root_2" => 2},
               grammar_encoding: encoded
             } = EBNF.encode(grammar)

      assert encoded ==
               [1, 10, 2, 97, 122, 2, 111, 111, 2, 107, 107, 0, 0] ++
                 [2, 5, 1, 1, 1, 2, 0, 1, 0, 0, 0, 3, 1, 2, 0, 0, 65535]
    end

    test "charset repetition" do
      grammar = fixture("charset_repetition.gbnf")

      assert %ParseState{symbol_ids: symbol_ids, grammar_encoding: encoded} = EBNF.encode(grammar)
      assert %{"ws" => 0, "ws_1" => 1} = symbol_ids

      assert encoded == [
               1,
               10,
               6,
               32,
               32,
               9,
               9,
               10,
               10,
               1,
               1,
               0,
               1,
               0,
               0,
               0,
               3,
               1,
               1,
               0,
               0,
               65535
             ]
    end

    test "concatenation of rule, grouped, and repetition" do
      grammar = fixture("concat_rule_grouped_repetition.gbnf")

      assert %ParseState{symbol_ids: symbol_ids, grammar_encoding: encoded} = EBNF.encode(grammar)
      assert %{"expr" => 0, "term" => 1, "expr_2" => 2, "expr_3" => 3} = symbol_ids

      assert encoded ==
               [2, 12, 8, 45, 45, 43, 43, 42, 42, 47, 47, 1, 1, 0, 0] ++
                 [3, 5, 1, 2, 1, 3, 0, 1, 0, 0, 0, 5, 1, 1, 1, 3, 0] ++
                 [0, 1, 7, 2, 111, 111, 2, 107, 107, 0, 0, 65535]
    end

    test "simple arithmetic" do
      grammar = fixture("simple_arithmetic.gbnf")

      assert %ParseState{symbol_ids: symbol_ids, grammar_encoding: encoded} = EBNF.encode(grammar)

      assert %{
               "root" => 0,
               "root_1" => 1,
               "expr" => 2,
               "ws" => 3,
               "term" => 4,
               "root_5" => 5,
               "expr_6" => 6,
               "expr_7" => 7,
               "num" => 8,
               "num_9" => 9,
               "ws_10" => 10
             } = symbol_ids

      assert encoded ==
               [1, 13, 1, 2, 2, 61, 61, 1, 3, 1, 4, 2, 10, 10, 0, 0, 5, 5] ++
                 [1, 1, 1, 5, 0, 3, 1, 1, 0, 0, 0, 3, 1, 5, 0, 0, 6, 12, 8] ++
                 [45, 45, 43, 43, 42, 42, 47, 47, 1, 4, 0, 0, 7, 5, 1, 6, 1] ++
                 [7, 0, 1, 0, 0, 2, 5, 1, 4, 1, 7, 0, 0, 4, 3, 1, 8, 0, 13, 2] ++
                 [40, 40, 1, 3, 1, 2, 2, 41, 41, 1, 3, 0, 0, 9, 6, 2, 48, 57, 1] ++
                 [9, 0, 4, 2, 48, 57, 0, 0, 8, 5, 1, 9, 1, 3, 0, 0, 10, 10, 6] ++
                 [32, 32, 9, 9, 10, 10, 1, 10, 0, 1, 0, 0, 3, 3, 1, 10, 0, 0, 65535]
    end

    test "json" do
      grammar = fixture("json.gbnf")

      assert %ParseState{symbol_ids: symbol_ids, grammar_encoding: encoded} = EBNF.encode(grammar)

      assert %{
               "root" => 0,
               "object" => 1,
               "ws" => 2,
               "object_3" => 3,
               "string" => 4,
               "value" => 5,
               "object_6" => 6,
               "object_7" => 7,
               "object_8" => 8,
               "array" => 9,
               "number" => 10,
               "value_11" => 11,
               "array_12" => 12,
               "array_13" => 13,
               "array_14" => 14,
               "array_15" => 15,
               "string_16" => 16,
               "string_17" => 17,
               "number_18" => 18,
               "number_19" => 19,
               "number_20" => 20,
               "number_21" => 21,
               "number_22" => 22,
               "number_23" => 23,
               "number_24" => 24,
               "number_25" => 25,
               "number_26" => 26,
               "number_27" => 27,
               "number_28" => 28,
               "ws_29" => 29,
               "ws_30" => 30
             } = symbol_ids

      assert encoded ==
               [0, 3, 1, 1, 0, 0, 6, 15, 2, 44, 44, 1, 2, 1, 4, 2, 58] ++
                 [58, 1, 2, 1, 5, 0, 0, 7, 5, 1, 6, 1, 7, 0, 1, 0, 0] ++
                 [3, 12, 1, 4, 2, 58, 58, 1, 2, 1, 5, 1, 7, 0, 0, 8, 3] ++
                 [1, 3, 0, 1, 0, 0, 1, 11, 2, 123, 123, 1, 2, 1, 8, 2] ++
                 [125, 125, 0, 0, 11, 13, 2, 116, 116, 2, 114, 114, 2] ++
                 [117, 117, 2, 101, 101, 0, 16, 2, 102, 102, 2, 97, 97] ++
                 [2, 108, 108, 2, 115, 115, 2, 101, 101, 0, 13, 2, 110] ++
                 [110, 2, 117, 117, 2, 108, 108, 2, 108, 108, 0, 0, 5, 3] ++
                 [1, 1, 0, 3, 1, 9, 0, 3, 1, 4, 0, 3, 1, 10, 0, 5, 1, 11] ++
                 [1, 2, 0, 0, 13, 8, 2, 44, 44, 1, 2, 1, 5, 0, 0, 14, 5, 1] ++
                 [13, 1, 14, 0, 1, 0, 0, 12, 5, 1, 5, 1, 14, 0, 0, 15, 3, 1] ++
                 [12, 0, 1, 0, 0, 9, 13, 2, 91, 91, 1, 2, 1, 15, 2, 93, 93] ++
                 [1, 2, 0, 0, 16, 8, 6, 97, 122, 65, 90, 48, 57, 0, 0, 17] ++
                 [5, 1, 16, 1, 17, 0, 1, 0, 0, 4, 11, 2, 34, 34, 1, 17, 2] ++
                 [34, 34, 1, 2, 0, 0, 19, 4, 2, 45, 45, 0, 1, 0, 0, 21, 6] ++
                 [2, 48, 57, 1, 21, 0, 1, 0, 0, 20, 4, 2, 48, 57, 0, 6, 2] ++
                 [49, 57, 1, 21, 0, 0, 18, 5, 1, 19, 1, 20, 0, 0, 23, 6, 2] ++
                 [48, 57, 1, 23, 0, 4, 2, 48, 57, 0, 0, 22, 6, 2, 46, 46, 1] ++
                 [23, 0, 0, 24, 3, 1, 22, 0, 1, 0, 0, 26, 6, 4, 45, 45, 43] ++
                 [43, 0, 1, 0, 0, 27, 6, 2, 48, 57, 1, 27, 0, 4, 2, 48, 57] ++
                 [0, 0, 25, 10, 4, 101, 101, 69, 69, 1, 26, 1, 27, 0, 0, 28] ++
                 [3, 1, 25, 0, 1, 0, 0, 10, 9, 1, 18, 1, 24, 1, 28, 1, 2, 0] ++
                 [0, 29, 10, 6, 32, 32, 9, 9, 10, 10, 1, 2, 0, 0, 30, 3, 1] ++
                 [29, 0, 1, 0, 0, 2, 3, 1, 30, 0, 0, 65535]
    end
  end

  defp fixture(file) do
    Path.join(["test", "fixtures", file])
    |> File.read!()
  end
end
