import Lake
open Lake DSL

package «lean_constant_data» where
  -- add package configuration options here

lean_lib «LeanConstantData» where
  -- add library configuration options here

@[default_target]
lean_exe «lean_constant_data» where
  root := `Main
