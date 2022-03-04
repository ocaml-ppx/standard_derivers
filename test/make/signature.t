---------------------------------------------------
NOTICE: @@ocaml.doc and @@merlin.hide annotations
& `include struct` boilerplate are added by ppxlib.
---------------------------------------------------

Test 1: Given a regular record type a, expose make_a
  $ test1="
  > type a = {
  >   x: int ;
  >   y: bool }[@@deriving make]"
  $ echo "$test1" > test.mli
  $ driver test.mli 
  type a = {
    x: int ;
    y: bool }[@@deriving make]
  include sig [@@@ocaml.warning "-32"] val make_a : x:int -> y:bool -> a end
  [@@ocaml.doc "@inline"][@@merlin.hide ]

Test 2: Given a nonrec type, embed error
  $ test2="
  > type nonrec b = {
  >   x: int ;
  >   y: bool }[@@deriving make]"
  $ echo "$test2" > test.mli
  $ driver test.mli
  type nonrec b = {
    x: int ;
    y: bool }[@@deriving make]
  include
    sig
      [@@@ocaml.warning "-32"]
      [%%ocaml.error "nonrec is not compatible with the `make' preprocessor."]
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Test 3: Given a non-record type, embed error
  $ test3="
  > type c = int * int
  > [@@deriving make]"
  $ echo "$test3" > test.mli
  $ driver test.mli
  type c = (int * int)[@@deriving make]
  include
    sig
      [@@@ocaml.warning "-32"]
      [%%ocaml.error
        "Unsupported use of make (you can only use it on records)."]
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Test 4: Given a private type, embed error
  $ test4="
  > type d = private {
  >   x: int ;
  >   y: bool }[@@deriving make]"
  $ echo "$test4" > test.mli
  $ driver test.mli
  type d = private {
    x: int ;
    y: bool }[@@deriving make]
  include
    sig
      [@@@ocaml.warning "-32"]
      [%%ocaml.error
        "We cannot expose functions that explicitly create private records."]
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Test 5: Given recursive types which are exclusively
record types, expose 1 make function for each record 
  $ test5="
  > type e = {
  >   v: f ;
  >   w: bool }
  > and f = {
  >   x: int ;
  >   mutable y: bool ;
  >   z: e }[@@deriving make]"
  $ echo "$test5" > test.mli
  $ driver test.mli
  type e = {
    v: f ;
    w: bool }
  and f = {
    x: int ;
    mutable y: bool ;
    z: e }[@@deriving make]
  include
    sig
      [@@@ocaml.warning "-32"]
      val make_e : v:f -> w:bool -> e
      val make_f : x:int -> y:bool -> z:e -> f
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Test 6: Given recursive types with at least one 
record type, expose 1 make function for each type 
  $ test6="
  > type g = int*h
  > and h = {
  >   v: g ;
  >   w: bool }[@@deriving make]"
  $ echo "$test6" > test.mli  
  $ driver test.mli
  type g = (int * h)
  and h = {
    v: g ;
    w: bool }[@@deriving make]
  include sig [@@@ocaml.warning "-32"] val make_h : v:g -> w:bool -> h end
  [@@ocaml.doc "@inline"][@@merlin.hide ]

Test 7: Given recursive types without any record
types, embed error
  $ test7="
  > type i = int*j
  > and j = bool*i [@@deriving make]"
  $ echo "$test7" > test.mli  
  $ driver test.mli
  type i = (int * j)
  and j = (bool * i)[@@deriving make]
  include
    sig
      [@@@ocaml.warning "-32"]
      [%%ocaml.error
        "make can only be applied on type definitions in which at least one type definition is a record."]
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
