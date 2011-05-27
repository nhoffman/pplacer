open Subcommand
open Guppy_cmdobjs
open MapsSets
open Fam_batteries

let flip f x y = f y x

class cmd () =
object (self)
  inherit subcommand () as super
  inherit mass_cmd () as super_mass
  inherit refpkg_cmd ~required:false as super_refpkg
  inherit placefile_cmd () as super_placefile
  inherit output_cmd () as super_output

  val trimmed_tree_file = flag "-t"
    (Needs_argument ("trimmed tree file", "If specified, the path to write the trimmed tree to."))
  val leaf_mass = flag "-m"
    (Plain (0.0, "The amount of mass to be distributed across all leaves."))
  val mass_cutoff = flag "--cutoff"
    (Formatted (0.001, "The minimum mass cutoff. Default: %1.6f"))

  method specl =
    super_mass#specl
    @ super_refpkg#specl
    @ super_output#specl
    @ [
      string_flag trimmed_tree_file;
      float_flag leaf_mass;
      float_flag mass_cutoff;
    ]

  method desc = "apply voronoi"
  method usage = "usage: voronoi [options] placefile"

  method private placefile_action = function
    | [pr] ->
      let transform, weighting, criterion = self#mass_opts
      and gt = Placerun.get_ref_tree pr in
      let mass = Mass_map.Indiv.of_placerun transform weighting criterion pr
      and graph = Voronoi.of_gtree gt in
      let n_leaves = IntSet.cardinal graph.Voronoi.all_leaves in
      let mass =
        IntSet.fold
          (flip IntMap.add_listly (0.0, (fv leaf_mass) /. (float_of_int n_leaves)))
          graph.Voronoi.all_leaves
          mass
      in
      let mass_dist = Voronoi.distribute_mass graph mass in
      IntMap.iter
        (fun e fl ->
          Printf.printf "%d " e;
          List.iter (Printf.printf "%0.6f ") fl;
          print_newline ())
        mass_dist;
      let sum = List.fold_left (+.) 0.0 in
      let rec aux graph =
        let mass_dist = Voronoi.distribute_mass graph mass in
        let sum_leaf leaf = sum (IntMap.get leaf [] mass_dist) in
        match IntSet.fold
          (fun leaf ->
            let mass = sum_leaf leaf in function
              | None -> Some (IntSet.singleton leaf, mass)
              | Some (_, prev_mass) when mass < prev_mass ->
                Some (IntSet.singleton leaf, mass)
              | Some (leafs, prev_mass) when mass = prev_mass ->
                Some (IntSet.add leaf leafs, prev_mass)
              | (Some _) as prev -> prev)
          graph.Voronoi.all_leaves
          None
        with
          | None -> failwith "no leaves?"
          | Some (leafs, mass) ->
            Printf.printf "smallest mass: %1.6f; %d leaves cut; %d leaves remaining"
              mass
              (IntSet.cardinal leafs)
              (IntSet.cardinal graph.Voronoi.all_leaves);
            print_newline ();
            let graph', updated = Voronoi.uncolor_leaves graph leafs in
            IntSet.ppr Format.std_formatter updated;
            Format.print_newline ();
            if mass >= fv mass_cutoff then begin
              Printf.printf "remaining: ";
              IntSet.ppr Format.std_formatter graph.Voronoi.all_leaves;
              Format.print_newline ();
              graph'
            end else
              aux graph'
      in
      let graph' = aux graph in
      let trimmed =
        IntSet.diff
          graph.Voronoi.all_leaves
          graph'.Voronoi.all_leaves
      in
      let decor_map = IntSet.fold
        (flip IntMap.add [Decor.red])
        trimmed
        IntMap.empty
      in
      let decor = Decor_gtree.add_decor_by_map
        (Decor_gtree.of_newick_gtree gt)
        decor_map
      in
      Phyloxml.named_gtrees_to_file "cut.xml" [Some "cut leaves", decor]

    | _ -> failwith "voronoi takes exactly one placefile"

end
