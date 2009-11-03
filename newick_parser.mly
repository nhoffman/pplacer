%token CR EOF COLON SEMICOLON COMMA OPENP CLOSEP 
%token <string> LABEL REAL

%start tree
%type<Newick_bark.newick_bark_type Gtree.gtree> tree
%%

%{
  let node_num = ref (-1)
  let bark_map = ref Bark_map.empty
  let add_bark b = bark_map := Bark_map.add !node_num b !bark_map
  let add_name name = 
    add_bark ((Bark_map.find_loose !node_num !bark_map)#set_name name)
  let add_boot boot = 
    add_bark ((Bark_map.find_loose !node_num !bark_map)#set_boot boot)
  let add_bl bl = 
    add_bark ((Bark_map.find_loose !node_num !bark_map)#set_bl bl)
  let add_leaf leafname = 
    incr node_num;
    add_name leafname;
    Stree.leaf !node_num
  let add_internal tL = 
    incr node_num;
    Stree.node !node_num tL
%}

naked_subtree:
  | LABEL
  { add_leaf $1 }
  | REAL
  { add_leaf $1 }
  | OPENP subtree_list CLOSEP
  { add_internal $2 }

subtree:
  | subtree COLON REAL
  { add_bl (float_of_string $3); $1 }
  | subtree REAL
  { add_boot (float_of_string $2); $1 }
  | naked_subtree
  { $1 }

subtree_list:
  | subtree COMMA subtree_list
  { $1 :: $3}
  | subtree
  { [$1] }
  
nosemitree: 
  | subtree 
  { 
    let result = Gtree.gtree $1 !bark_map in
    (* clear things out for the next tree *)
    node_num := -1;
    bark_map := Bark_map.empty;
    result
  }

tree: 
  | nosemitree SEMICOLON
  { $1 }
  | nosemitree
  { $1 }
