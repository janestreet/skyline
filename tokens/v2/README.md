# Skyline Tokens

Design tokens for the Skyline design system, represented as `Css_gen` values for use
with CSS generation.

## Usage

```ocaml
open skyline_tokens_v2

(* Use with ppx_css *)
let styles =
  {%css|
    color: %{Colors.Text.primary#Css_gen.Color};
    background-color: %{Colors.Background.one#Css_gen.Color};
    border: 1px solid %{Colors.Border.default#Css_gen.Color};
    padding: 16px;
  |}

(* Create custom theme-aware colors *)
let custom = Colors.color ~light:(`Hex "#1a1a1a") ~dark:(`Hex "#fafafa")
```

## Color Categories

- **Text**: `default`, `secondary`, `link`, `disabled`, semantic variants (`primary`, `danger`, `success`, `warning`)
- **Background**: Surface levels (`one`, `two`, `three`), semantic variants with hover/active states
- **Border**: `default` and semantic variants
- **Shadow**: `default` and semantic variants

All colors automatically adapt between light and dark themes.
