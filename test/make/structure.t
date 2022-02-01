---------------------------------------------------
NOTICE: @@ocaml.doc and @@merlin.hide annotations
& `include struct` boilerplate are added by ppxlib.
---------------------------------------------------

Test 1: Given a regular record type a, derive make_a
  $ test1="
  > type a = {
  >   x: int ;
  >   y: bool }[@@deriving make]"
  $ echo "$test1" > test.ml
  $ driver test.ml
  type a = {
    x: int ;
    y: bool }[@@deriving make]
  include
    struct
      let _ = fun (_ : a) -> ()
      let make_a ~x  ~y  = { x; y }
      let _ = make_a
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Test 2: Given a nonrec type, throw error
  $ test2="
  > type nonrec b = {
  >   x: int ;
  >   y: bool }[@@deriving make]"
  $ echo "$test2" > test.ml
  $ driver test.ml
  File "test.ml", lines 2-4, characters 0-28:
  2 | type nonrec b = {
  3 |   x: int ;
  4 |   y: bool }[@@deriving make]
  Error: nonrec is not compatible with the `make' preprocessor.
  [1]

Test 3: Given a non-record type, throw error
  $ test3="
  > type c = int * int
  > [@@deriving make]"
  $ echo "$test3" > test.ml
  $ driver test.ml
  File "test.ml", lines 2-3, characters 0-17:
  2 | type c = int * int
  3 | [@@deriving make]
  Error: Unsupported use of make (you can only use it on records).
  [1]

Test 4: Given a private record type d, derive make_d
  $ test4="
  > type d = private {
  >   x: int ;
  >   y: bool }[@@deriving make]"
  $ echo "$test4" > test.ml
  $ driver test.ml
  type d = private {
    x: int ;
    y: bool }[@@deriving make]
  include struct let _ = fun (_ : d) -> () end[@@ocaml.doc "@inline"][@@merlin.hide
                                                                      ]

Test 5: Given recursive types which are exclusively
record types, derive 1 make function for each record 
  $ test5="
  > type e = {
  >   v: f ;
  >   w: bool }
  > and f = {
  >   x: int ;
  >   mutable y: bool ;
  >   z: e }[@@deriving make]"
  $ echo "$test5" > test.ml  
  $ driver test.ml
  type e = {
    v: f ;
    w: bool }
  and f = {
    x: int ;
    mutable y: bool ;
    z: e }[@@deriving make]
  include
    struct
      let _ = fun (_ : e) -> ()
      let _ = fun (_ : f) -> ()
      let make_e ~v  ~w  = { v; w }
      let _ = make_e
      let make_f ~x  ~y  ~z  = { x; y; z }
      let _ = make_f
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Test 6: Given recursive types with at least one 
record type, derive one make function for each type 
  $ test6="
  > type g = int*h
  > and h = {
  >   v: g ;
  >   w: bool }[@@deriving make]"
  $ echo "$test6" > test.ml  
  $ driver test.ml
  type g = (int * h)
  and h = {
    v: g ;
    w: bool }[@@deriving make]
  include
    struct
      let _ = fun (_ : g) -> ()
      let _ = fun (_ : h) -> ()
      let make_h ~v  ~w  = { v; w }
      let _ = make_h
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Test 7: Given recursive types without any record
types, throw error
  $ test7="
  > type i = int*j
  > and i = bool*j [@@deriving make]"
  $ echo "$test7" > test.ml  
  $ driver test.ml
  File "test.ml", lines 2-3, characters 0-32:
  2 | type i = int*j
  3 | and i = bool*j [@@deriving make]
  Error: make can only be applied on type definitions in which at least one type definition is a record.
  [1]

Test 8: Given a record type k with an `option` 
field, derive make_k
  $ test8="
  > type k = {
  >   x: int ;
  >   y: bool option }[@@deriving make]"
  $ echo "$test8" > test.ml
  $ driver test.ml
  type k = {
    x: int ;
    y: bool option }[@@deriving make]
  include
    struct
      let _ = fun (_ : k) -> ()
      let make_k ~x  ?y  = { x; y }
      let _ = make_k
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
