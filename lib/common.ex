defmodule Plasm.Common do
    @doc "Convert a UTF16 string to the UTF8. We need to do this because erlang stores their database return information as UTF16 but Elixir uses UTF8"
    def convert_utf16_to_utf8(raw) do
        :unicode.characters_to_binary(raw, {:utf16, :little})
    end
end