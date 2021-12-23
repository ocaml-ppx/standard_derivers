(* Generated code should depend on the environment in scope as little as
   possible.  E.g. rather than [foo = []] do [match foo with [] ->], to eliminate the
   use of [=].  It is especially important to not use polymorphic comparisons, since we
   are moving more and more to code that doesn't have them in scope. *)

   open Base
   open Ppxlib
   open Ast_builder.Default
   
   let check_no_collision =
     let always = [ "create" ] in
     fun (lbls : label_declaration list) ->
       let generated_funs =
         let extra_forbidden_names =
           List.filter_map lbls ~f:(function
             | { pld_mutable = Mutable; pld_name; _ } -> Some ("set_" ^ pld_name.txt)
             | _ -> None)
         in
         ("set_all_mutable_fields" :: extra_forbidden_names) @ always
       in
       List.iter lbls ~f:(fun { pld_name; pld_loc; _ } ->
         if List.mem generated_funs pld_name.txt ~equal:String.equal
         then
           Location.raise_errorf
             ~loc:pld_loc
             "ppx_fields_conv: field name %S conflicts with one of the generated functions"
             pld_name.txt)
   ;;
   
   module A = struct
     (* Additional AST construction helpers *)
   
     let str_item ~loc name body =
       pstr_value ~loc Nonrecursive [ value_binding ~loc ~pat:(pvar ~loc name) ~expr:body ]
     ;;
   
     (* let mod_ ~loc : string -> structure -> structure_item =
       fun name structure ->
         pstr_module
           ~loc
           (module_binding
              ~loc
              ~name:(Located.mk ~loc (Some name))
              ~expr:(pmod_structure ~loc structure))
     ;; *)
   
     let sig_item ~loc name typ =
       psig_value
         ~loc
         (value_description ~loc ~name:(Located.mk ~loc name) ~type_:typ ~prim:[])
     ;;
   end
   
   module Create = struct
     let record ~loc pairs =
       pexp_record
         ~loc
         (List.map pairs ~f:(fun (name, exp) -> Located.lident ~loc name, exp))
         None
     ;;
   
     let lambda ~loc patterns body =
       List.fold_right patterns ~init:body ~f:(fun (lab, pat) acc ->
         pexp_fun ~loc lab None pat acc)
     ;;
   
     let lambda_sig ~loc arg_tys body_ty =
       List.fold_right arg_tys ~init:body_ty ~f:(fun (lab, arg_ty) acc ->
         ptyp_arrow ~loc lab arg_ty acc)
     ;;
   end
   
   module Inspect = struct
     let field_names labdecs = List.map labdecs ~f:(fun labdec -> labdec.pld_name.txt)
   end
   
   let check_at_least_one_record ~loc rec_flag tds =
     (match rec_flag with
      | Nonrecursive ->
        Location.raise_errorf ~loc "nonrec is not compatible with the `fields' preprocessor"
      | _ -> ());
     let is_record td =
       match td.ptype_kind with
       | Ptype_record _ -> true
       | _ -> false
     in
     if not (List.exists tds ~f:is_record)
     then
       Location.raise_errorf
         ~loc
         (match tds with
          | [ _ ] -> "Unsupported use of fields (you can only use it on records)."
          | _ ->
            "'with fields' can only be applied on type definitions in which at least one \
             type definition is a record")
   ;;
   
   module Gen_sig = struct
     let apply_type ~loc ~ty_name ~tps = ptyp_constr ~loc (Located.lident ~loc ty_name) tps
     let label_arg name ty = Labelled name, ty
   
     let create_fun ~ty_name ~tps ~loc labdecs =
       let record = apply_type ~loc ~ty_name ~tps in
       let f labdec =
         let { pld_name = name; pld_type = ty; _ } = labdec in
         label_arg name.txt ty
       in
       let types = List.map labdecs ~f in
       let t = Create.lambda_sig ~loc types record in
       A.sig_item ~loc "create" t
     ;;
   
     let record
           ~private_
           ~ty_name
           ~tps
           ~loc
           (labdecs : label_declaration list)
       : signature
       =
       let create_fun = create_fun ~ty_name ~tps ~loc labdecs in
                (match private_ with
                   (* The ['perm] phantom type prohibits first-class fields from mutating or
                      creating private records, so we can expose them (and fold, etc.).
   
                      However, we still can't expose functions that explicitly create private
                      records. *)
                   | Private -> []
                   | Public -> [ create_fun ])
     ;;
   
     let create_of_td (td : type_declaration) : signature =
       let { ptype_name = { txt = ty_name; loc }
           ; ptype_private = private_
           ; ptype_params
           ; ptype_kind
           ; _
           }
         =
         td
       in
       let tps = List.map ptype_params ~f:(fun (tp, _variance) -> tp) in
       match ptype_kind with
       | Ptype_record labdecs ->
         check_no_collision labdecs;
         record ~private_ ~ty_name ~tps ~loc labdecs
       | _ -> []
     ;;
   
     let generate ~loc ~path:_ (rec_flag, tds) =
       check_at_least_one_record ~loc rec_flag tds;
       List.concat_map tds ~f:(create_of_td)
     ;;
   end
   
   module Gen_struct = struct
     let label_arg ?label ~loc name =
       let l =
         match label with
         | None -> name
         | Some n -> n
       in
       Labelled l, pvar ~loc name
     ;;
   
     let creation_fun ~loc _record_name labdecs =
       let names = Inspect.field_names labdecs in
       let f = Create.record ~loc (List.map names ~f:(fun n -> n, evar ~loc n)) in
       let patterns = List.map names ~f:(fun x -> label_arg ~loc x) in
       let f = Create.lambda ~loc patterns f in
       A.str_item ~loc "create" f
     ;;
   
     let record
           ~private_
           ~record_name
           ~loc
           (labdecs : label_declaration list)
       : structure
       =
       let create = creation_fun ~loc record_name labdecs in
       (match private_ with
         | Private -> []
         | Public -> [ create ])
     ;;
   
     let create_of_td (td : type_declaration) : structure =
       let { ptype_name = { txt = record_name; loc }
           ; ptype_private = private_
           ; ptype_kind
           ; _
           }
         =
         td
       in
       match ptype_kind with
       | Ptype_record labdecs ->
         check_no_collision labdecs;
         record ~private_ ~record_name ~loc labdecs
       | _ -> []
     ;;
   
     let generate ~loc ~path:_ (rec_flag, tds) =
       check_at_least_one_record ~loc rec_flag tds;
       List.concat_map tds ~f:(create_of_td)
     ;;
   end
   
   let create =
     Deriving.add "create"
       ~str_type_decl:
         (Deriving.Generator.make_noarg Gen_struct.generate)
       ~sig_type_decl:(Deriving.Generator.make_noarg Gen_sig.generate)
   ;;
   