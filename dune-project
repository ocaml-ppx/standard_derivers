(lang dune 3.0)

(cram enable)

(generate_opam_files true)

(name standard_derivers)

(source
 (github  ocaml-ppx/standard_derivers))

(package
 (name standard_derivers)
 (synopsis "Standard PPX derivers")
 (depends
  (ppxlib (>= 0.18.0)))
 (allow_empty))
