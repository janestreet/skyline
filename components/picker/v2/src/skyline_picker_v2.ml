(** Picker components for selecting values from a list of options.

    [Skyline_picker_v2] provides three input components:

    - {!Select_input} — a button-triggered dropdown for choosing from a static list
    - {!Typeahead_select_input} — a button-triggered dropdown with a search input for
      fuzzy filtering
    - {!Typeahead_combobox_input} — a text input with typeahead filtering for searching
      and selecting from a potentially large set of options

    Both typeahead inputs share a {!Typeahead_controller}.

    All three render as {!Skyline_field_v2.Content.t} and inherit [size], [intent], and
    [disabled] from the enclosing field. *)

module Typeahead_controller = struct
  include Typeahead_controller
  module Data_source = Typeahead_data_source
  module Highlighted_splits = Highlighted_splits
end

module Typeahead_combobox_input = Typeahead_combobox_input
module Typeahead_select_input = Typeahead_select_input

module Typeahead = struct
  module Controller = Typeahead_controller
  module Combobox_input = Typeahead_combobox_input
  module Select_input = Typeahead_select_input
end

module Select_input = struct
  include Select_input
  module Options = Select_options
end
