(* Test 1: regular record type *)
type a = 
  { x : int
  ; y : bool
  }
[@@deriving_inline make]

include 
  sig 
    [@@@ocaml.warning "-32"] 
    val make_a : x:int -> y:bool -> a 
  end [@@ocaml.doc "@inline"]
[@@@end]

(* Test 2: recursive record types *)
type b = 
  { v : c
  ; w : bool
  }
and c =
  { x : int
  ; mutable y : bool
  ; z : b
  }
[@@deriving_inline make]

include
  sig
    [@@@ocaml.warning "-32"]
    val make_b : v:c -> w:bool -> b
    val make_c : x:int -> y:bool -> z:b -> c
  end [@@ocaml.doc "@inline"]
[@@@end]

(* Test 3: invalid non-record type *)
(* type d = int * int
[@@deriving_inline make]
[@@@end] *)
