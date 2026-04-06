open! Core
open! Private_skyline_prelude

module Position = struct
  type t = Bonsai_web_toplayer.Position.t =
    | Auto
    | Top
    | Bottom
    | Left
    | Right
  [@@deriving sexp, equal, compare, enumerate]
end

module Offset = struct
  type t = Bonsai_web_toplayer.Offset.t =
    { main_axis : float
    ; cross_axis : float
    }
  [@@deriving sexp, equal, compare]
end

module Alignment = struct
  type t = Bonsai_web_toplayer.Alignment.t =
    | Center
    | Start
    | End
  [@@deriving sexp_of]
end

module Color = struct
  type t =
    [ `Success
    | `Danger
    | `Warning
    ]
  [@@deriving sexp_of, equal, enumerate, to_string]
end

module Style = struct
  let text = {%css|max-width: 400px;|}

  let default_bg =
    Css_gen.Color.light_dark
      (Palette.black :> Css_gen.Color.t)
      (Palette.zinc600 :> Css_gen.Color.t)
  ;;

  include
    [%css
    stylesheet
      {|
        /* --- Animations --- */
        @keyframes skyline-tooltip-in {
          from {
            opacity: 0;
            transform: scale(0.95);
            /* Prevent pointer events while animating because the moving tooltip can receive hover events */
            pointer-events: none;
          }
          to {
            opacity: 1;
            transform: scale(1);
            pointer-events: auto;
          }
        }
        @keyframes skyline-tooltip-in-from-top {
          from {
            opacity: 0;
            transform: translateY(-8px) scale(0.95);
            /* Prevent pointer events while animating because the moving tooltip can receive hover events */
            pointer-events: none;
          }
          to {
            opacity: 1;
            transform: translateY(0) scale(1);
            pointer-events: auto;
          }
        }
        @keyframes skyline-tooltip-in-from-bottom {
          from {
            opacity: 0;
            transform: translateY(8px) scale(0.95);
            /* Prevent pointer events while animating because the moving tooltip can receive hover events */
            pointer-events: none;
          }
          to {
            opacity: 1;
            transform: translateY(0) scale(1);
            pointer-events: auto;
          }
        }
        @keyframes skyline-tooltip-in-from-left {
          from {
            opacity: 0;
            transform: translateX(-8px) scale(0.95);
            /* Prevent pointer events while animating because the moving tooltip can receive hover events */
            pointer-events: none;
          }
          to {
            opacity: 1;
            transform: translateX(0) scale(1);
            pointer-events: auto;
          }
        }
        @keyframes skyline-tooltip-in-from-right {
          from {
            opacity: 0;
            transform: translateX(8px) scale(0.95);
            /* Prevent pointer events while animating because the moving tooltip can receive hover events */
            pointer-events: none;
          }
          to {
            opacity: 1;
            transform: translateX(0) scale(1);
            pointer-events: auto;
          }
        }

        .tooltip-animate {
          /* Fallback animation (fade + zoom) in case side-specific selectors don't apply */
          animation: skyline-tooltip-in 150ms ease-out both;
          transform-origin: var(--radix-tooltip-content-transform-origin, center);
          will-change: transform, opacity;
        }
        /* It's kinda sad that we're hard-coding `data-floating-placement` here, but it's not core to tooltip behavior so maybe fine. */
        .tooltip-animate[data-floating-placement^="top"] {
          animation-name: skyline-tooltip-in-from-bottom;
        }
        .tooltip-animate[data-floating-placement^="bottom"] {
          animation-name: skyline-tooltip-in-from-top;
        }
        .tooltip-animate[data-floating-placement^="left"] {
          animation-name: skyline-tooltip-in-from-right;
        }
        .tooltip-animate[data-floating-placement^="right"] {
          animation-name: skyline-tooltip-in-from-left;
        }

        .tooltip-default {
          background-color: %{default_bg#Css_gen.Color};
          color: %{Palette.white#Css_gen.Color};
          /* NB: we tried to implement semi-transparent backgrounds, and it's a bit
             complicated. We can't generate a token for the bg color because it needs to
             be applied to both the body of the tooltip and the arrow. If the opacity is
             applied separately then you either:
             1. get subpixel artifacts where you can see between the gap, or
             2. see the double opacity applied where there is overlap.
             So it's better to set `opacity` on the whole DOM subtree directly instead of
             alpha channel on the bg color so that the tooltip+main content can blend
             correctly. This has a drawback though of also affecting the opacity of text
             content, so it only works for high opacity values. */

          & .arrow {
            background-color: %{default_bg#Css_gen.Color};
          }
        }

        .tooltip-red {
          background-color: %{Palette.red700#Css_gen.Color};
          color: %{Palette.white#Css_gen.Color};

          & .arrow {
            background-color: %{Palette.red700#Css_gen.Color};
          }
        }

        .tooltip-yellow {
          background-color: %{Palette.yellow400#Css_gen.Color};
          color: %{Palette.yellow950#Css_gen.Color};

          & .arrow {
            background-color: %{Palette.yellow400#Css_gen.Color};
          }
        }

        .tooltip-green {
          background-color: %{Palette.green700#Css_gen.Color};
          color: %{Palette.white#Css_gen.Color};
          & .arrow {
            background-color: %{Palette.green700#Css_gen.Color};
          }
        }

        .arrow {
          width: 10px;
          height: 10px;
          transform: rotate(45deg);
          /* The `transform` above seems to break the hover target on Mac OS / Linux
             so we just disable pointer events entirely */
          pointer-events: none;
          /* The underlying arrow impl from toplayer already rotates this div by a dynamic
             amount so top-left is always pointing toward the anchor */
          border-top-left-radius: 2px;
        }
      |}]

  let of_color = function
    | None -> tooltip_default
    | Some `Success -> tooltip_green
    | Some `Danger -> tooltip_red
    | Some `Warning -> tooltip_yellow
  ;;

  let make ~color ~attrs =
    [ Classes.rounded_xs
    ; Classes.px 2.
    ; Classes.py 1.
    ; Classes.border_none
    ; tooltip_animate
    ; of_color color
    ; Vdom.Attr.many attrs
    ]
  ;;
end

let arrow_node = [%html {|<div %{Style.arrow}></div>|}]

let attr
  ?test_selector
  ?(attrs = [])
  ?color
  ?(position = Position.Auto)
  ?(offset = Offset.{ main_axis = 4.; cross_axis = 0. })
  ?(alignment = Alignment.Center)
  ?(behavior = `Non_interactive)
  ?(arrow = `Default)
  content
  =
  let attrs = Style.make ~color ~attrs in
  let view =
    {%html|
      <div
        *{Classes.[flex; flex_col; text_xs]}
        %{Test_selector.attr_of_opt test_selector}
        %{Classes.data_skyline_component "tooltip"}
      >
        %{content}
      </div>
    |}
  in
  let arrow =
    match arrow with
    | `Default -> Some arrow_node
    | `None -> None
  in
  match behavior with
  | `Always_closed -> Attr.empty
  | `Always_show ->
    Bonsai_web_toplayer.vdom_popover
      ~popover_attrs:attrs
      ~offset
      ~position
      ~alignment
      ~overflow_auto_wrapper:true
      ?arrow
      view
  | `Interactive | `Non_interactive ->
    let interactive =
      match behavior with
      | `Interactive -> true
      | _ -> false
    in
    Bonsai_web_toplayer.tooltip
      ~tooltip_attrs:attrs
      ~offset
      ~position
      ~alignment
      ~light_dismiss:false
      ~hoverable_inside:interactive
      ?hide_grace_period:(if interactive then Some (Time_ns.Span.of_sec 0.1) else None)
      ~show_delay:(Time_ns.Span.of_ms 150.)
      ?arrow
      view
;;

let text_attr
  ?test_selector
  ?attrs
  ?color
  ?position
  ?offset
  ?alignment
  ?behavior
  ?arrow
  content
  =
  attr
    ?test_selector
    ?attrs
    ?color
    ?position
    ?offset
    ?alignment
    ?behavior
    ?arrow
    [%html {|<span %{Style.text}> #{content} </span>|}]
;;

module For_docs = struct
  let ml_filepath = __FILE__
end
