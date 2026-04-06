open! Core

module Stable = struct
  module Hue = struct
    module V1 = struct
      type t =
        [ `slate
        | `gray
        | `zinc
        | `neutral
        | `stone
        | `red
        | `orange
        | `amber
        | `yellow
        | `lime
        | `green
        | `emerald
        | `teal
        | `cyan
        | `sky
        | `blue
        | `indigo
        | `violet
        | `purple
        | `fuchsia
        | `pink
        | `rose
        ]
      [@@deriving bin_io, compare, enumerate, equal, sexp, sexp_grammar]
    end
  end
end

module Hue = struct
  module T = struct
    type t = Stable.Hue.V1.t [@@deriving enumerate, sexp_of, equal]
  end

  include T
  include Enum.Make_stringable (T)
end

module Brightness = struct
  type t =
    [ `_50
    | `_100
    | `_200
    | `_300
    | `_400
    | `_500
    | `_600
    | `_700
    | `_800
    | `_900
    | `_950
    ]
  [@@deriving enumerate]

  let to_string = function
    | `_50 -> "50"
    | `_100 -> "100"
    | `_200 -> "200"
    | `_300 -> "300"
    | `_400 -> "400"
    | `_500 -> "500"
    | `_600 -> "600"
    | `_700 -> "700"
    | `_800 -> "800"
    | `_900 -> "900"
    | `_950 -> "950"
  ;;
end

let oklch l c h =
  let l = Percent.of_mult l in
  (* NOTE: unlike most percentages in css, the float range goes from [0, 0.4] rather than
     [0, 1]. Therefore we divide by the max value to get the right Percent.

     For more details, see:
     https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/oklch#c
  *)
  let c = Percent.of_mult (c /. 0.4) in
  `OKLCHA (Css_gen.Color.OKLCHA.create ~l ~c ~h ())
;;

(* black and white palette *)
let black = oklch 0. 0. 0.
let white = oklch 1. 0. 0.

(* red palette *)
let red50 = oklch 0.971 0.013 17.38
let red100 = oklch 0.936 0.032 17.717
let red200 = oklch 0.885 0.062 18.334
let red300 = oklch 0.808 0.114 19.571
let red400 = oklch 0.704 0.191 22.216
let red500 = oklch 0.637 0.237 25.331
let red600 = oklch 0.577 0.245 27.325
let red700 = oklch 0.505 0.213 27.518
let red800 = oklch 0.444 0.177 26.899
let red900 = oklch 0.396 0.141 25.723
let red950 = oklch 0.258 0.092 26.042

(* orange palette *)
let orange50 = oklch 0.98 0.016 73.684
let orange100 = oklch 0.954 0.038 75.164
let orange200 = oklch 0.901 0.076 70.697
let orange300 = oklch 0.837 0.128 66.29
let orange400 = oklch 0.75 0.183 55.934
let orange500 = oklch 0.705 0.213 47.604
let orange600 = oklch 0.646 0.222 41.116
let orange700 = oklch 0.553 0.195 38.402
let orange800 = oklch 0.47 0.157 37.304
let orange900 = oklch 0.408 0.123 38.172
let orange950 = oklch 0.266 0.079 36.259

(* amber palette *)
let amber50 = oklch 0.987 0.022 95.277
let amber100 = oklch 0.962 0.059 95.617
let amber200 = oklch 0.924 0.12 95.746
let amber300 = oklch 0.879 0.169 91.605
let amber400 = oklch 0.828 0.189 84.429
let amber500 = oklch 0.769 0.188 70.08
let amber600 = oklch 0.666 0.179 58.318
let amber700 = oklch 0.555 0.163 48.998
let amber800 = oklch 0.473 0.137 46.201
let amber900 = oklch 0.414 0.112 45.904
let amber950 = oklch 0.279 0.077 45.635

(* yellow palette *)
let yellow50 = oklch 0.987 0.026 102.212
let yellow100 = oklch 0.973 0.071 103.193
let yellow200 = oklch 0.945 0.129 101.54
let yellow300 = oklch 0.905 0.182 98.111
let yellow400 = oklch 0.852 0.199 91.936
let yellow500 = oklch 0.795 0.184 86.047
let yellow600 = oklch 0.681 0.162 75.834
let yellow700 = oklch 0.554 0.135 66.442
let yellow800 = oklch 0.476 0.114 61.907
let yellow900 = oklch 0.421 0.095 57.708
let yellow950 = oklch 0.286 0.066 53.813

(* lime palette *)
let lime50 = oklch 0.986 0.031 120.757
let lime100 = oklch 0.967 0.067 122.328
let lime200 = oklch 0.938 0.127 124.321
let lime300 = oklch 0.897 0.196 126.665
let lime400 = oklch 0.841 0.238 128.85
let lime500 = oklch 0.768 0.233 130.85
let lime600 = oklch 0.648 0.2 131.684
let lime700 = oklch 0.532 0.157 131.589
let lime800 = oklch 0.453 0.124 130.933
let lime900 = oklch 0.405 0.101 131.063
let lime950 = oklch 0.274 0.072 132.109

(* green palette *)
let green50 = oklch 0.982 0.018 155.826
let green100 = oklch 0.962 0.044 156.743
let green200 = oklch 0.925 0.084 155.995
let green300 = oklch 0.871 0.15 154.449
let green400 = oklch 0.792 0.209 151.711
let green500 = oklch 0.723 0.219 149.579
let green600 = oklch 0.627 0.194 149.214
let green700 = oklch 0.527 0.154 150.069
let green800 = oklch 0.448 0.119 151.328
let green900 = oklch 0.393 0.095 152.535
let green950 = oklch 0.266 0.065 152.934

(* emerald palette *)
let emerald50 = oklch 0.979 0.021 166.113
let emerald100 = oklch 0.95 0.052 163.051
let emerald200 = oklch 0.905 0.093 164.15
let emerald300 = oklch 0.845 0.143 164.978
let emerald400 = oklch 0.765 0.177 163.223
let emerald500 = oklch 0.696 0.17 162.48
let emerald600 = oklch 0.596 0.145 163.225
let emerald700 = oklch 0.508 0.118 165.612
let emerald800 = oklch 0.432 0.095 166.913
let emerald900 = oklch 0.378 0.077 168.94
let emerald950 = oklch 0.262 0.051 172.552

(* teal palette *)
let teal50 = oklch 0.984 0.014 180.72
let teal100 = oklch 0.953 0.051 180.801
let teal200 = oklch 0.91 0.096 180.426
let teal300 = oklch 0.855 0.138 181.071
let teal400 = oklch 0.777 0.152 181.912
let teal500 = oklch 0.704 0.14 182.503
let teal600 = oklch 0.6 0.118 184.704
let teal700 = oklch 0.511 0.096 186.391
let teal800 = oklch 0.437 0.078 188.216
let teal900 = oklch 0.386 0.063 188.416
let teal950 = oklch 0.277 0.046 192.524

(* cyan palette *)
let cyan50 = oklch 0.984 0.019 200.873
let cyan100 = oklch 0.956 0.045 203.388
let cyan200 = oklch 0.917 0.08 205.041
let cyan300 = oklch 0.865 0.127 207.078
let cyan400 = oklch 0.789 0.154 211.53
let cyan500 = oklch 0.715 0.143 215.221
let cyan600 = oklch 0.609 0.126 221.723
let cyan700 = oklch 0.52 0.105 223.128
let cyan800 = oklch 0.45 0.085 224.283
let cyan900 = oklch 0.398 0.07 227.392
let cyan950 = oklch 0.302 0.056 229.695

(* sky palette *)
let sky50 = oklch 0.977 0.013 236.62
let sky100 = oklch 0.951 0.026 236.824
let sky200 = oklch 0.901 0.058 230.902
let sky300 = oklch 0.828 0.111 230.318
let sky400 = oklch 0.746 0.16 232.661
let sky500 = oklch 0.685 0.169 237.323
let sky600 = oklch 0.588 0.158 241.966
let sky700 = oklch 0.5 0.134 242.749
let sky800 = oklch 0.443 0.11 240.79
let sky900 = oklch 0.391 0.09 240.876
let sky950 = oklch 0.293 0.066 243.157

(* blue palette *)
let blue50 = oklch 0.97 0.014 254.604
let blue100 = oklch 0.932 0.032 255.585
let blue200 = oklch 0.882 0.059 254.128
let blue300 = oklch 0.809 0.105 251.813
let blue400 = oklch 0.707 0.165 254.624
let blue500 = oklch 0.623 0.214 259.815
let blue600 = oklch 0.546 0.245 262.881
let blue700 = oklch 0.488 0.243 264.376
let blue800 = oklch 0.424 0.199 265.638
let blue900 = oklch 0.379 0.146 265.522
let blue950 = oklch 0.282 0.091 267.935

(* indigo palette *)
let indigo50 = oklch 0.962 0.018 272.314
let indigo100 = oklch 0.93 0.034 272.788
let indigo200 = oklch 0.87 0.065 274.039
let indigo300 = oklch 0.785 0.115 274.713
let indigo400 = oklch 0.673 0.182 276.935
let indigo500 = oklch 0.585 0.233 277.117
let indigo600 = oklch 0.511 0.262 276.966
let indigo700 = oklch 0.457 0.24 277.023
let indigo800 = oklch 0.398 0.195 277.366
let indigo900 = oklch 0.359 0.144 278.697
let indigo950 = oklch 0.257 0.09 281.288

(* violet palette *)
let violet50 = oklch 0.969 0.016 293.756
let violet100 = oklch 0.943 0.029 294.588
let violet200 = oklch 0.894 0.057 293.283
let violet300 = oklch 0.811 0.111 293.571
let violet400 = oklch 0.702 0.183 293.541
let violet500 = oklch 0.606 0.25 292.717
let violet600 = oklch 0.541 0.281 293.009
let violet700 = oklch 0.491 0.27 292.581
let violet800 = oklch 0.432 0.232 292.759
let violet900 = oklch 0.38 0.189 293.745
let violet950 = oklch 0.283 0.141 291.089

(* purple palette *)
let purple50 = oklch 0.977 0.014 308.299
let purple100 = oklch 0.946 0.033 307.174
let purple200 = oklch 0.902 0.063 306.703
let purple300 = oklch 0.827 0.119 306.383
let purple400 = oklch 0.714 0.203 305.504
let purple500 = oklch 0.627 0.265 303.9
let purple600 = oklch 0.558 0.288 302.321
let purple700 = oklch 0.496 0.265 301.924
let purple800 = oklch 0.438 0.218 303.724
let purple900 = oklch 0.381 0.176 304.987
let purple950 = oklch 0.291 0.149 302.717

(* fuchsia palette *)
let fuchsia50 = oklch 0.977 0.017 320.058
let fuchsia100 = oklch 0.952 0.037 318.852
let fuchsia200 = oklch 0.903 0.076 319.62
let fuchsia300 = oklch 0.833 0.145 321.434
let fuchsia400 = oklch 0.74 0.238 322.16
let fuchsia500 = oklch 0.667 0.295 322.15
let fuchsia600 = oklch 0.591 0.293 322.896
let fuchsia700 = oklch 0.518 0.253 323.949
let fuchsia800 = oklch 0.452 0.211 324.591
let fuchsia900 = oklch 0.401 0.17 325.612
let fuchsia950 = oklch 0.293 0.136 325.661

(* pink palette *)
let pink50 = oklch 0.971 0.014 343.198
let pink100 = oklch 0.948 0.028 342.258
let pink200 = oklch 0.899 0.061 343.231
let pink300 = oklch 0.823 0.12 346.018
let pink400 = oklch 0.718 0.202 349.761
let pink500 = oklch 0.656 0.241 354.308
let pink600 = oklch 0.592 0.249 0.584
let pink700 = oklch 0.525 0.223 3.958
let pink800 = oklch 0.459 0.187 3.815
let pink900 = oklch 0.408 0.153 2.432
let pink950 = oklch 0.284 0.109 3.907

(* rose palette *)
let rose50 = oklch 0.969 0.015 12.422
let rose100 = oklch 0.941 0.03 12.58
let rose200 = oklch 0.892 0.058 10.001
let rose300 = oklch 0.81 0.117 11.638
let rose400 = oklch 0.712 0.194 13.428
let rose500 = oklch 0.645 0.246 16.439
let rose600 = oklch 0.586 0.253 17.585
let rose700 = oklch 0.514 0.222 16.935
let rose800 = oklch 0.455 0.188 13.697
let rose900 = oklch 0.41 0.159 10.272
let rose950 = oklch 0.271 0.105 12.094

(* slate palette *)
let slate50 = oklch 0.984 0.003 247.858
let slate100 = oklch 0.968 0.007 247.896
let slate200 = oklch 0.929 0.013 255.508
let slate300 = oklch 0.869 0.022 252.894
let slate400 = oklch 0.704 0.04 256.788
let slate500 = oklch 0.554 0.046 257.417
let slate600 = oklch 0.446 0.043 257.281
let slate700 = oklch 0.372 0.044 257.287
let slate800 = oklch 0.279 0.041 260.031
let slate900 = oklch 0.208 0.042 265.755
let slate950 = oklch 0.129 0.042 264.695

(* gray palette *)
let gray50 = oklch 0.985 0.002 247.839
let gray100 = oklch 0.967 0.003 264.542
let gray200 = oklch 0.928 0.006 264.531
let gray300 = oklch 0.872 0.01 258.338
let gray400 = oklch 0.707 0.022 261.325
let gray500 = oklch 0.551 0.027 264.364
let gray600 = oklch 0.446 0.03 256.802
let gray700 = oklch 0.373 0.034 259.733
let gray800 = oklch 0.278 0.033 256.848
let gray900 = oklch 0.21 0.034 264.665
let gray950 = oklch 0.13 0.028 261.692

(* zinc palette *)
let zinc50 = oklch 0.985 0. 0.
let zinc100 = oklch 0.967 0.001 286.375
let zinc200 = oklch 0.92 0.004 286.32
let zinc300 = oklch 0.871 0.006 286.286
let zinc400 = oklch 0.705 0.015 286.067
let zinc500 = oklch 0.552 0.016 285.938
let zinc600 = oklch 0.442 0.017 285.786
let zinc700 = oklch 0.37 0.013 285.805
let zinc800 = oklch 0.274 0.006 286.033
let zinc900 = oklch 0.21 0.006 285.885
let zinc950 = oklch 0.141 0.005 285.823

(* neutral palette *)
let neutral50 = oklch 0.985 0. 0.
let neutral100 = oklch 0.97 0. 0.
let neutral200 = oklch 0.922 0. 0.
let neutral300 = oklch 0.87 0. 0.
let neutral400 = oklch 0.708 0. 0.
let neutral500 = oklch 0.556 0. 0.
let neutral600 = oklch 0.439 0. 0.
let neutral700 = oklch 0.371 0. 0.
let neutral800 = oklch 0.269 0. 0.
let neutral900 = oklch 0.205 0. 0.
let neutral950 = oklch 0.145 0. 0.

(* stone palette *)
let stone50 = oklch 0.985 0.001 106.423
let stone100 = oklch 0.97 0.001 106.424
let stone200 = oklch 0.923 0.003 48.717
let stone300 = oklch 0.869 0.005 56.366
let stone400 = oklch 0.709 0.01 56.259
let stone500 = oklch 0.553 0.013 58.071
let stone600 = oklch 0.444 0.011 73.639
let stone700 = oklch 0.374 0.01 67.558
let stone800 = oklch 0.268 0.007 34.298
let stone900 = oklch 0.216 0.006 56.043
let stone950 = oklch 0.147 0.004 49.25

let create (hue : Hue.t) (brightness : Brightness.t) =
  match hue with
  | `slate ->
    (match brightness with
     | `_50 -> slate50
     | `_100 -> slate100
     | `_200 -> slate200
     | `_300 -> slate300
     | `_400 -> slate400
     | `_500 -> slate500
     | `_600 -> slate600
     | `_700 -> slate700
     | `_800 -> slate800
     | `_900 -> slate900
     | `_950 -> slate950)
  | `gray ->
    (match brightness with
     | `_50 -> gray50
     | `_100 -> gray100
     | `_200 -> gray200
     | `_300 -> gray300
     | `_400 -> gray400
     | `_500 -> gray500
     | `_600 -> gray600
     | `_700 -> gray700
     | `_800 -> gray800
     | `_900 -> gray900
     | `_950 -> gray950)
  | `zinc ->
    (match brightness with
     | `_50 -> zinc50
     | `_100 -> zinc100
     | `_200 -> zinc200
     | `_300 -> zinc300
     | `_400 -> zinc400
     | `_500 -> zinc500
     | `_600 -> zinc600
     | `_700 -> zinc700
     | `_800 -> zinc800
     | `_900 -> zinc900
     | `_950 -> zinc950)
  | `neutral ->
    (match brightness with
     | `_50 -> neutral50
     | `_100 -> neutral100
     | `_200 -> neutral200
     | `_300 -> neutral300
     | `_400 -> neutral400
     | `_500 -> neutral500
     | `_600 -> neutral600
     | `_700 -> neutral700
     | `_800 -> neutral800
     | `_900 -> neutral900
     | `_950 -> neutral950)
  | `stone ->
    (match brightness with
     | `_50 -> stone50
     | `_100 -> stone100
     | `_200 -> stone200
     | `_300 -> stone300
     | `_400 -> stone400
     | `_500 -> stone500
     | `_600 -> stone600
     | `_700 -> stone700
     | `_800 -> stone800
     | `_900 -> stone900
     | `_950 -> stone950)
  | `red ->
    (match brightness with
     | `_50 -> red50
     | `_100 -> red100
     | `_200 -> red200
     | `_300 -> red300
     | `_400 -> red400
     | `_500 -> red500
     | `_600 -> red600
     | `_700 -> red700
     | `_800 -> red800
     | `_900 -> red900
     | `_950 -> red950)
  | `orange ->
    (match brightness with
     | `_50 -> orange50
     | `_100 -> orange100
     | `_200 -> orange200
     | `_300 -> orange300
     | `_400 -> orange400
     | `_500 -> orange500
     | `_600 -> orange600
     | `_700 -> orange700
     | `_800 -> orange800
     | `_900 -> orange900
     | `_950 -> orange950)
  | `amber ->
    (match brightness with
     | `_50 -> amber50
     | `_100 -> amber100
     | `_200 -> amber200
     | `_300 -> amber300
     | `_400 -> amber400
     | `_500 -> amber500
     | `_600 -> amber600
     | `_700 -> amber700
     | `_800 -> amber800
     | `_900 -> amber900
     | `_950 -> amber950)
  | `yellow ->
    (match brightness with
     | `_50 -> yellow50
     | `_100 -> yellow100
     | `_200 -> yellow200
     | `_300 -> yellow300
     | `_400 -> yellow400
     | `_500 -> yellow500
     | `_600 -> yellow600
     | `_700 -> yellow700
     | `_800 -> yellow800
     | `_900 -> yellow900
     | `_950 -> yellow950)
  | `lime ->
    (match brightness with
     | `_50 -> lime50
     | `_100 -> lime100
     | `_200 -> lime200
     | `_300 -> lime300
     | `_400 -> lime400
     | `_500 -> lime500
     | `_600 -> lime600
     | `_700 -> lime700
     | `_800 -> lime800
     | `_900 -> lime900
     | `_950 -> lime950)
  | `green ->
    (match brightness with
     | `_50 -> green50
     | `_100 -> green100
     | `_200 -> green200
     | `_300 -> green300
     | `_400 -> green400
     | `_500 -> green500
     | `_600 -> green600
     | `_700 -> green700
     | `_800 -> green800
     | `_900 -> green900
     | `_950 -> green950)
  | `emerald ->
    (match brightness with
     | `_50 -> emerald50
     | `_100 -> emerald100
     | `_200 -> emerald200
     | `_300 -> emerald300
     | `_400 -> emerald400
     | `_500 -> emerald500
     | `_600 -> emerald600
     | `_700 -> emerald700
     | `_800 -> emerald800
     | `_900 -> emerald900
     | `_950 -> emerald950)
  | `teal ->
    (match brightness with
     | `_50 -> teal50
     | `_100 -> teal100
     | `_200 -> teal200
     | `_300 -> teal300
     | `_400 -> teal400
     | `_500 -> teal500
     | `_600 -> teal600
     | `_700 -> teal700
     | `_800 -> teal800
     | `_900 -> teal900
     | `_950 -> teal950)
  | `cyan ->
    (match brightness with
     | `_50 -> cyan50
     | `_100 -> cyan100
     | `_200 -> cyan200
     | `_300 -> cyan300
     | `_400 -> cyan400
     | `_500 -> cyan500
     | `_600 -> cyan600
     | `_700 -> cyan700
     | `_800 -> cyan800
     | `_900 -> cyan900
     | `_950 -> cyan950)
  | `sky ->
    (match brightness with
     | `_50 -> sky50
     | `_100 -> sky100
     | `_200 -> sky200
     | `_300 -> sky300
     | `_400 -> sky400
     | `_500 -> sky500
     | `_600 -> sky600
     | `_700 -> sky700
     | `_800 -> sky800
     | `_900 -> sky900
     | `_950 -> sky950)
  | `blue ->
    (match brightness with
     | `_50 -> blue50
     | `_100 -> blue100
     | `_200 -> blue200
     | `_300 -> blue300
     | `_400 -> blue400
     | `_500 -> blue500
     | `_600 -> blue600
     | `_700 -> blue700
     | `_800 -> blue800
     | `_900 -> blue900
     | `_950 -> blue950)
  | `indigo ->
    (match brightness with
     | `_50 -> indigo50
     | `_100 -> indigo100
     | `_200 -> indigo200
     | `_300 -> indigo300
     | `_400 -> indigo400
     | `_500 -> indigo500
     | `_600 -> indigo600
     | `_700 -> indigo700
     | `_800 -> indigo800
     | `_900 -> indigo900
     | `_950 -> indigo950)
  | `violet ->
    (match brightness with
     | `_50 -> violet50
     | `_100 -> violet100
     | `_200 -> violet200
     | `_300 -> violet300
     | `_400 -> violet400
     | `_500 -> violet500
     | `_600 -> violet600
     | `_700 -> violet700
     | `_800 -> violet800
     | `_900 -> violet900
     | `_950 -> violet950)
  | `purple ->
    (match brightness with
     | `_50 -> purple50
     | `_100 -> purple100
     | `_200 -> purple200
     | `_300 -> purple300
     | `_400 -> purple400
     | `_500 -> purple500
     | `_600 -> purple600
     | `_700 -> purple700
     | `_800 -> purple800
     | `_900 -> purple900
     | `_950 -> purple950)
  | `fuchsia ->
    (match brightness with
     | `_50 -> fuchsia50
     | `_100 -> fuchsia100
     | `_200 -> fuchsia200
     | `_300 -> fuchsia300
     | `_400 -> fuchsia400
     | `_500 -> fuchsia500
     | `_600 -> fuchsia600
     | `_700 -> fuchsia700
     | `_800 -> fuchsia800
     | `_900 -> fuchsia900
     | `_950 -> fuchsia950)
  | `pink ->
    (match brightness with
     | `_50 -> pink50
     | `_100 -> pink100
     | `_200 -> pink200
     | `_300 -> pink300
     | `_400 -> pink400
     | `_500 -> pink500
     | `_600 -> pink600
     | `_700 -> pink700
     | `_800 -> pink800
     | `_900 -> pink900
     | `_950 -> pink950)
  | `rose ->
    (match brightness with
     | `_50 -> rose50
     | `_100 -> rose100
     | `_200 -> rose200
     | `_300 -> rose300
     | `_400 -> rose400
     | `_500 -> rose500
     | `_600 -> rose600
     | `_700 -> rose700
     | `_800 -> rose800
     | `_900 -> rose900
     | `_950 -> rose950)
;;
