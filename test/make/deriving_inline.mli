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

include
  sig
    [@@@ocaml.warning "-32"]
    val make_t : x:int -> y:bool -> z:r -> t
    val make_r : a:t -> b:bool -> r
  end[@@ocaml.doc "@inline"]

[@@@end]
