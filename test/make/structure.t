---------------------------------------------------
NOTICE: @@ocaml.doc and @@merlin.hide annotations
& `include struct` boilerplate are added by ppxlib.
---------------------------------------------------
The `-deriving-keep-w32 both` flag added after the 
driver removes anonymous functions of the type: 
-   let _ = fun (_ : t) -> ()
-   let _ = make_t
which are automatically added by ppxlib.
---------------------------------------------------

Test 1: Given a regular record type a, derive make_a
  $ test1="
  > type a = {
  >   x: int ;
  >   y: bool }[@@deriving make]"
  $ echo "$test1" > test.ml
  $ driver -deriving-keep-w32 both test.ml
  type a = {
    x: int ;
    y: bool }[@@deriving make]
  include struct let make_a ~x  ~y  = { x; y } end[@@ocaml.doc "@inline"]
  [@@merlin.hide ]

Test 2: Given a nonrec type, embed error
  $ test2="
  > type nonrec b = {
  >   x: int ;
  >   y: bool }[@@deriving make]"
  $ echo "$test2" > test.ml
  $ driver -deriving-keep-w32 both test.ml
  type nonrec b = {
    x: int ;
    y: bool }[@@deriving make]
  include
    struct
      [%%ocaml.error
        "deriver make: nonrec is not compatible with the `make' preprocessor."]
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Test 3: Given a non-record type, embed error
  $ test3="
  > type c = int * int
  > [@@deriving make]"
  $ echo "$test3" > test.ml
  $ driver -deriving-keep-w32 both test.ml
  type c = (int * int)[@@deriving make]
  include
    struct
      [%%ocaml.error
        "deriver make: Unsupported use of make (you can only use it on records)."]
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Test 4: Given a private record type d, derive make_d
  $ test4="
  > type d = private {
  >   x: int ;
  >   y: bool }[@@deriving make]"
  $ echo "$test4" > test.ml
  $ driver -deriving-keep-w32 both test.ml
  type d = private {
    x: int ;
    y: bool }[@@deriving make]
  include struct  end[@@ocaml.doc "@inline"][@@merlin.hide ]

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
  $ driver -deriving-keep-w32 both test.ml
  type e = {
    v: f ;
    w: bool }
  and f = {
    x: int ;
    mutable y: bool ;
    z: e }[@@deriving make]
  include
    struct
      let make_e ~v  ~w  = { v; w }
      let make_f ~x  ~y  ~z  = { x; y; z }
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Test 6: Given recursive types with at least one 
record type, derive one make function for each record 
  $ test6="
  > type g = int*h
  > and h = {
  >   v: g ;
  >   w: bool }[@@deriving make]"
  $ echo "$test6" > test.ml  
  $ driver -deriving-keep-w32 both test.ml
  type g = (int * h)
  and h = {
    v: g ;
    w: bool }[@@deriving make]
  include struct let make_h ~v  ~w  = { v; w } end[@@ocaml.doc "@inline"]
  [@@merlin.hide ]

Test 7: Given recursive types without any record
types, embed error
  $ test7="
  > type i = int*j
  > and i = bool*j [@@deriving make]"
  $ echo "$test7" > test.ml  
  $ driver -deriving-keep-w32 both test.ml
  type i = (int * j)
  and i = (bool * j)[@@deriving make]
  include
    struct
      [%%ocaml.error
        "deriver make: make can only be applied on type definitions in which at least one type definition is a record."]
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
