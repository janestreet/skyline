open! Core

let raised_card =
  Css_gen.create
    ~field:"box-shadow"
    ~value:
      "0 1px 3px 0 var(--skyline-shadow, rgb(0 0 0 / 0.1)), 0 1px 2px -1px \
       var(--skyline-shadow, rgb(0 0 0 / 0.1))"
;;

let floating_card =
  Css_gen.create
    ~field:"box-shadow"
    ~value:
      "0 4px 6px -1px var(--skyline-shadow, rgb(0 0 0 / 0.1)), 0 2px 4px -2px \
       var(--skyline-shadow, rgb(0 0 0 / 0.1))"
;;
