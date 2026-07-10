open! Core
open! Bonsai_web
open Bonsai.Let_syntax
open Bonsai_garden_docs_common
module Focusable_list = Bonsai_web_focusable_list

let component (graph @ local) =
  let%demo_md docs =
    [ `Markdown
        {|
# Bonsai_web_focusable_list

A state-machine helper for building keyboard-navigable lists with a **roving
tabindex**.

A roving tabindex list always has exactly one focusable item — that item
gets `tabindex="0"`, all other items get `tabindex="-1"`. This means Tab
moves focus into and out of the list as a single stop, while arrow keys (or
any other keyboard handler you wire up) move focus between items inside it.

The library tracks:

- which item is currently focusable, and
- whether the list currently has DOM focus (via focusin/focusout).

Programmatic `.focus()` calls only happen while the list has DOM focus, so
items being added or removed while the user has tabbed elsewhere will not
steal focus back.

> ⚠️This is an expert library and mostly intended for advanced use cases. It
is quite low-level and requires some knowledge of keyboard navigation and
web concepts to use. It may be better to try building without it first, and
if you need it, you can add it then.

## Example

The list below renders four fruits. Click an item to focus it, then press
`ArrowDown`/`ArrowUp` (or `Home`/`End`) to move between them. Tab into and
out of the list to see that the whole list is a single tab stop.

Use the `wrap_around` checkbox to toggle whether navigation past the end
wraps to the start (and vice versa).
|}
    ; singleton_doc
        ~codeblock_max_height:(`Raw "25lh")
        (Both
           (let view, demo_string =
              [%demo
                let fruits = [ "Apple"; "Banana"; "Cherry"; "Durian" ] in
                let wrap_around, set_wrap_around = Bonsai.state false graph in
                let ids = Bonsai.return (Iarray.of_list fruits) in
                let focusable_list, inject =
                  Focusable_list.create ~wrap_around (module String) ids graph
                in
                let item_attr = Focusable_list.item_attr focusable_list in
                let on_keydown =
                  let%arr inject in
                  fun (evt : Js_of_ocaml.Dom_html.keyboardEvent Js_of_ocaml.Js.t) ->
                    match Js_of_ocaml.Dom_html.Keyboard_code.of_event evt with
                    | ArrowDown ->
                      evt##preventDefault;
                      inject Next |> Effect.ignore_m
                    | ArrowUp ->
                      evt##preventDefault;
                      inject Prev |> Effect.ignore_m
                    | Home ->
                      evt##preventDefault;
                      inject First |> Effect.ignore_m
                    | End ->
                      evt##preventDefault;
                      inject Last |> Effect.ignore_m
                    | _ -> Effect.Ignore
                in
                let%arr focusable_list
                and item_attr
                and on_keydown
                and wrap_around
                and set_wrap_around in
                let focused =
                  Focusable_list.focusable focusable_list
                  |> Option.value ~default:"(none)"
                in
                let container_attr = Focusable_list.container_attr focusable_list in
                let items =
                  List.map fruits ~f:(fun id ->
                    let is_focusable =
                      [%equal: string option]
                        (Focusable_list.focusable focusable_list)
                        (Some id)
                    in
                    let background = if is_focusable then "#eef2ff" else "white" in
                    {%html|
                      <li
                        %{item_attr id}
                        style="
                          padding: 6px 12px;
                          border-bottom: 1px solid #e5e7eb;
                          background-color: %{background};
                          cursor: pointer;
                          outline: none;
                        "
                      >
                        %{id#String}
                      </li>
                    |})
                in
                {%html|
                  <div style="display: flex; flex-direction: column; gap: 8px">
                    <label
                      style="
                        display: flex;
                        gap: 6px;
                        align-items: center;
                        font-family: monospace;
                        font-size: 13px;
                      "
                    >
                      <input
                        type="checkbox"
                        %{Vdom.Attr.bool_property "checked" wrap_around}
                        on_click=%{fun _ -> set_wrap_around (not wrap_around)}
                      />
                      <span>wrap_around</span>
                    </label>
                    <ul
                      %{container_attr}
                      %{Vdom.Attr.on_keydown on_keydown}
                      style="
                        margin: 0;
                        padding: 0;
                        list-style: none;
                        border: 1px solid #d1d5db;
                        border-radius: 4px;
                        font-family: monospace;
                        font-size: 14px;
                        width: 200px;
                      "
                    >
                      *{items}
                    </ul>
                    <div
                      style="
                        font-family: monospace;
                        font-size: 12px;
                        color: #6b7280;
                        width: 300px;
                      "
                    >
                      Focusable: %{focused#String} · Has focus:
                      %{Bool.to_string (Focusable_list.has_focus focusable_list)#String}
                    </div>
                  </div>
                |}]
            in
            let%arr view in
            view, demo_string))
        graph
    ; `Markdown
        {|
## Wiring it up

There are three pieces to wire together:

- `container_attr` goes on the wrapping element. It listens for
  focusin/focusout so the library knows whether the list currently owns DOM
  focus, and only then will it programmatically move focus in response to
  navigation actions.
- `item_attr` is applied per item. It sets `tabindex` (0 for the focusable
  item, -1 otherwise), wires up click-to-focus, and tracks the underlying
  DOM element by id so the library can call `.focus()` on it.
- `inject` dispatches `Action.t` values (`Focus`, `Next`, `Prev`, `First`,
  `Last`). Wire it up to whatever keyboard handler your component
  needs — typically arrow keys on the container.

The component does not install a keyboard handler for you. You decide which
keys map to which actions, and whether to also dispatch `Focus` from
elsewhere (for example, from a search box selecting a result).

## State

`focusable t` returns the id of the currently focusable item, or `None` only
when the list is empty. When items are added or removed, the focusable
marker is automatically revalidated; if the previously focusable item is
gone, the closest still-present neighbour is chosen instead.

`has_focus t` reflects whether some item in the list currently has DOM
focus. Programmatic focus moves only happen while this is `true`.
|}
    ; `Component (Bonsai.return {%html|<br />|})
    ]
  in
  Bonsai_garden_markdown_render_engine.generate_docs docs graph
;;
