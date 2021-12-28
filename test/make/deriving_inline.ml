type t =
  { x : int
  ; mutable y : bool
  ; z: r
  }
and r = 
  { a: t
  ; b: bool
  }
[@@deriving_inline make]

let _ = fun (_ : t) -> ()
let _ = fun (_ : r) -> ()
let make_t ~x  ~y  ~z  = { x; y; z }
let _ = make_t
let make_r ~a  ~b  = { a; b }
let _ = make_r
[@@@end]
