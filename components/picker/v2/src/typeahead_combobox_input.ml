open! Core
open! Private_skyline_prelude

type ('a, 'selection) render_selection =
  | Render_multi :
      { on_backspace : unit Effect.t
      ; render : 'a list -> Vdom.Node.t
      }
      -> ('a, 'a list) render_selection

(* Data attributes used to scope DOM queries to chips belonging to a specific controller
   instance. *)
let chip_owner_data_attr = "data-skyline-combobox-chip-owner"
let chip_index_data_attr = "data-skyline-combobox-chip-index"

let chip_selector ~owner ~index =
  [%string
    {|[%{chip_owner_data_attr}="%{owner}"][%{chip_index_data_attr}="%{index#Int}"]|}]
;;

let focus_chip ~owner ~index =
  match%bind.Effect
    Effect.of_thunk (fun () ->
      Private_skyline_dom.Element.get_by_selector (chip_selector ~owner ~index))
  with
  | None -> Effect.Ignore
  | Some element -> Private_skyline_dom.Element.focus element
;;

let content
  (type a selection)
  ?test_selector
  ?(attrs = [])
  ?(input_attrs = [])
  ?(render_selection : (a, selection) render_selection option)
  ?(tab_selects_current_item = false)
  ~placeholder
  ~(controller : (a, selection) Typeahead_controller.t)
  ()
  =
  let (T selection_mode) = Typeahead_controller.Private.selection_mode controller in
  let state = Typeahead_controller.Private.combobox_input_state controller in
  match selection_mode with
  | Single_ux _ | Effect_only ->
    {%html|
      <Skyline_text_input_v2.Composite.content
        %{Typeahead_controller.Private.for_combobox_anchor controller}
        *{attrs}
      >
        <Skyline_text_input_v2.Composite.input
          ?test_selector
          *{input_attrs}
          %{Typeahead_controller.Private.for_combobox_input
              ~on_backspace_when_empty:(Typeahead_controller.Private.deselect_last controller)
              ~tab_selects_current_item
              controller}
          ~placeholder
          ~state
        />
        <Skyline_text_input_v2.Composite.icon
          ~icon:%{Lucide.chevron_down}
          ~color:%{fun ~disabled:_ -> Colors.Text.input_placeholder}
        />
      </>
    |}
  | Multi_ux _ ->
    let to_string = Typeahead_controller.Private.to_string controller in
    let deselect_item = Typeahead_controller.Private.deselect_item controller in
    let focus_input = Typeahead_controller.Private.focus_combobox_input controller in
    let path_id = Typeahead_controller.Private.path_id controller in
    let selected, _ = Typeahead_controller.state controller in
    let on_backspace_when_empty, custom_render =
      match render_selection with
      | Some (Render_multi { on_backspace; render }) -> on_backspace, Some render
      | None -> Typeahead_controller.Private.deselect_last controller, None
    in
    let num_chips = List.length selected in
    let on_arrow_left_at_start =
      match custom_render with
      | Some _ -> None
      | None ->
        (match num_chips with
         | 0 -> None
         | _ -> Some (focus_chip ~owner:path_id ~index:(num_chips - 1)))
    in
    let multi_content =
      Skyline_text_input_v2.Composite.Content.Expert.make
        (fun ~size ~intent:_ ~disabled ->
           let chip_size =
             match size with
             | `Xs -> `Xs
             | `Sm | `Md | `Lg -> `Sm
           in
           let chip_nodes =
             match custom_render with
             | Some render ->
               [ {%html|<div %{Skyline_field_v2.Content.Expert.exclude_from_label_forwarding}>%{render selected}</div>|}
               ]
             | None ->
               List.mapi selected ~f:(fun chip_index item ->
                 let label = to_string item in
                 let dismiss_button =
                   if disabled
                   then Node.none
                   else (
                     let on_click_dismiss =
                       Effect.Many [ deselect_item item; focus_input ]
                     in
                     let on_keydown
                       (evt : Js_of_ocaml.Dom_html.keyboardEvent Js_of_ocaml.Js.t)
                       =
                       let focus_chip_or_input ~target_index =
                         match target_index >= 0 && target_index < num_chips with
                         | true -> focus_chip ~owner:path_id ~index:target_index
                         | false -> focus_input
                       in
                       match Js_of_ocaml.Dom_html.Keyboard_code.of_event evt with
                       | Enter | NumpadEnter | Space ->
                         evt##preventDefault;
                         Effect.Many
                           (* NOTE: effect ordering is sensitive here. *)
                           [ focus_chip_or_input ~target_index:(chip_index + 1)
                           ; deselect_item item
                           ]
                       | Backspace ->
                         evt##preventDefault;
                         Effect.Many
                           (* NOTE: effect ordering is sensitive here. *)
                           [ focus_chip_or_input ~target_index:(chip_index - 1)
                           ; deselect_item item
                           ]
                       | ArrowLeft when chip_index > 0 ->
                         evt##preventDefault;
                         focus_chip ~owner:path_id ~index:(chip_index - 1)
                       | ArrowRight ->
                         evt##preventDefault;
                         focus_chip_or_input ~target_index:(chip_index + 1)
                       | _ -> Effect.Ignore
                     in
                     (* We can't implement this with <button> because that would interfere
                        with label forwarding for :hover. *)
                     {%html|
                       <div
                         %{Attr.tabindex 0}
                         role="button"
                         %{Attr.create chip_owner_data_attr path_id}
                         %{Attr.create chip_index_data_attr (Int.to_string chip_index)}
                         style="
                           display: inline-flex;
                           align-items: center;
                           justify-content: center;
                           cursor: pointer;
                           padding: 0;
                           margin: 0;
                           margin-left: 2px;
                           color: inherit;
                           opacity: 0.6;

                           &:hover {
                             opacity: 1;
                           }
                         "
                         %{Attr.on_click (fun _ -> on_click_dismiss)}
                         %{Attr.on_keydown on_keydown}
                         %{Attr.on_mousedown (fun evt ->
                           (* Prevent focus moving from the input to the dismiss target *)
                           evt##preventDefault;
                           Effect.Ignore)}
                       >
                         <Bonsai_web_icon.view ~size:%{`Px 12} ~icon:%{Lucide.x} />
                       </div>
                     |})
                 in
                 {%html|
                   <div
                     %{Skyline_field_v2.Content.Expert.exclude_from_label_forwarding}
                     style="line-height: 0"
                     ~key:%{label}
                   >
                     <Skyline_chip_v2.view
                       ~size:%{chip_size}
                       ~variant:%{Skyline_chip_v2.Variant.Soft}
                     >
                       <span>#{label}</span>
                       %{dismiss_button}
                     </>
                   </div>
                 |})
           in
           let value, set_value = state in
           let text_size =
             match size with
             | `Xs -> Classes.text_xs
             | `Sm | `Md | `Lg -> Classes.text_sm
           in
           let icon_size =
             match size with
             | `Xs -> Font.size_xs
             | `Sm | `Md | `Lg -> Font.size_sm
           in
           let maybe_disabled_attr =
             if disabled then Classes.disabled else Vdom.Attr.empty
           in
           (* We want the text input so the <input> and icon wrap as a single unit; we
              never want them on separate lines. *)
           let input_with_icon =
             {%html|
               <div
                 ~key:%{"input-with-icon"}
                 style="
                   display: inline-flex;
                   align-items: center;
                   gap: %{Classes.spacing 1.#Css_gen.Length};
                   flex: 1;
                   min-width: 100px;
                 "
               >
                 <input
                   %{Test_selector.attr_of_opt test_selector}
                   *{input_attrs}
                   %{Typeahead_controller.Private.for_combobox_input
                       ~on_backspace_when_empty
                       ?on_arrow_left_at_start
                       ~tab_selects_current_item
                       controller}
                   %{text_size}
                   %{maybe_disabled_attr}
                   style="
                     border: none;
                     color: inherit;
                     flex: 1;
                     min-width: 0;
                     outline: none;

                     &::placeholder {
                       color: %{Colors.Text.input_placeholder#Css_gen.Color};
                     }
                   "
                   placeholder=%{placeholder}
                   type="text"
                   %{Attr.value value}
                   on_input=%{fun _ new_value -> set_value new_value}
                 />
                 <Bonsai_web_icon.view
                   ~size:%{icon_size}
                   ~color:%{Colors.Text.input_placeholder}
                   ~icon:%{Lucide.chevron_down}
                 />
               </div>
             |}
           in
           let padding =
             match size with
             | `Xs | `Sm -> Attr.empty
             | `Md -> {%css|padding-block: 1px;|}
             | `Lg -> {%css|padding-block: 4px;|}
           in
           {%html|
             <div
               %{padding}
               style="
                 display: flex;
                 flex-wrap: wrap;
                 align-items: center;
                 gap: 2px;
                 flex: 1;
                 max-width: 100%;
               "
             >
               *{chip_nodes} %{input_with_icon}
             </div>
           |})
    in
    let attrs =
      [ Typeahead_controller.Private.for_combobox_anchor controller
      ; {%css|min-width: 200px;|}
      ]
      @ attrs
    in
    Skyline_text_input_v2.Composite.content ~attrs [ multi_content ]
;;

module For_testing = struct
  let chip_owner_data_attr = chip_owner_data_attr
  let chip_index_data_attr = chip_index_data_attr
end

module For_docs = struct
  let ml_filepath = [%here].pos_fname
end
