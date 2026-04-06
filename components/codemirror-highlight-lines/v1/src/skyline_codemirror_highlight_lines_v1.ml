open! Core

type t = start:int * stop:int [@@deriving equal, sexp_of]

module Style =
  [%css
  stylesheet
    {|
      .highlight-single,
      .highlight-start,
      .highlight-center,
      .highlight-end {
        background: #00b2ff33;
      }

      .highlight-single {
        border-radius: 4px;
      }
      .highlight-start {
        border-radius: 4px 4px 0 0;
      }
      .highlight-center {
        border-radius: 0;
      }
      .highlight-end {
        border-radius: 0 0 4px 4px;
      }
    |}]

let extension (~start, ~stop) =
  Codemirror.State.Facet.compute
    Codemirror.View.Editor_view.decorations'
    ~deps:[]
    ~get:(fun _ ->
      Js_of_ocaml.Js.wrap_callback (fun view ->
        let text =
          Codemirror.View.Editor_view.state view |> Codemirror.State.Editor_state.doc
        in
        let mark ~from ~to_ class_ =
          Codemirror.View.Decoration.Line_spec.create ~class_ ()
          |> Codemirror.View.Decoration.line
          |> Codemirror.View.Decoration.range ~from ~to_
        in
        (* Adjust the start-stop line range such that:
           - start >= 1 (codemirror lines are one-indexed)
           - start <= stop
           - stop <= #number of lines in document *)
        let lines = Codemirror.Text.Text.lines text in
        let start = max 1 (min start (min lines stop)) in
        let stop = max start (min lines stop) in
        let decorations =
          if start = stop
          then (
            let location =
              Codemirror.Text.Text.line text start |> Codemirror.Text.Line.from
            in
            [ mark ~from:location ~to_:location Style.For_referencing.highlight_single ])
          else
            List.init
              (stop - start + 1)
              ~f:(fun offset ->
                let line = start + offset in
                let location =
                  Codemirror.Text.Text.line text line |> Codemirror.Text.Line.from
                in
                let class_ =
                  if line = start
                  then Style.For_referencing.highlight_start
                  else if line = stop
                  then Style.For_referencing.highlight_end
                  else Style.For_referencing.highlight_center
                in
                mark ~from:location ~to_:location class_)
        in
        Codemirror.View.Decoration.set ~sort:false decorations))
;;
