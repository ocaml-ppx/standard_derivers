type t =
  { x : int
  ; mutable y : bool
  }
[@@deriving_inline create]

let _ = fun (_ : t) -> ()
let create ~x  ~y  = { x; y }
let _ = create

[@@@end]
