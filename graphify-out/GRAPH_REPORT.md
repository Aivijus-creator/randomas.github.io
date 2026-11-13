# Graph Report - randomas.github.io  (2026-11-13)

## Corpus Check
- Corpus is ~10,016 words - fits in a single context window. You may not need a graph.

## Summary
- 92 nodes · 149 edges · 8 communities (4 shown, 4 thin omitted)
- Extraction: 72% EXTRACTED · 28% INFERRED · 0% AMBIGUOUS · INFERRED: 42 edges (avg confidence: 0.85)
- Token cost: 188,740 input · 0 output

## Community Hubs (Navigation)
- Topology, UVs and Baking
- Export Validation Rules
- Kitchen Viewer Runtime
- 3D Skill Core Principles
- Kitchen Materials and Textures
- Ponytail Coding Skill
- Project Instructions

## God Nodes (most connected - your core abstractions)
1. `3D Modeling Patterns Reference` - 27 edges
2. `3D Modeling Validations Reference` - 18 edges
3. `3D Modeling Skill` - 11 edges
4. `UV Unwrapping Strategy` - 7 edges
5. `Export Pipeline Standards` - 6 edges
6. `loadModel()` - 6 edges
7. `High to Low Poly Baking` - 5 edges
8. `Asset Naming Conventions` - 5 edges
9. `fixMaterialOnce()` - 5 edges
10. `DECOR selected decor textures (oak, sand)` - 5 edges

## Surprising Connections (you probably didn't know these)
- `3D Modeling Skill Source Attribution` --references--> `3D Modeling Skill`  [INFERRED]
  .claude/skills/3d-modeling/SOURCE.md → .claude/skills/3d-modeling/SKILL.md
- `Quads Required for Deforming Meshes` --rationale_for--> `Anti-pattern: Modeling with N-gons`  [INFERRED]
  .claude/skills/3d-modeling/SKILL.md → .claude/skills/3d-modeling/references/patterns.md
- `Automatic UV Unwrap Is for Prototyping Only` --conceptually_related_to--> `UV Unwrapping Strategy`  [INFERRED]
  .claude/skills/3d-modeling/SKILL.md → .claude/skills/3d-modeling/references/patterns.md
- `apply_boolean_clean (Blender Python)` --semantically_similar_to--> `weld_modular_pieces (Blender Python)`  [INFERRED] [semantically similar]
  .claude/skills/3d-modeling/references/validations.md → .claude/skills/3d-modeling/references/patterns.md
- `Validation: Non-Power-of-Two Texture Dimensions` --conceptually_related_to--> `UV Unwrapping Strategy`  [INFERRED]
  .claude/skills/3d-modeling/references/validations.md → .claude/skills/3d-modeling/references/patterns.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Three-Part Reference System (Creation / Diagnosis / Review)** — _claude_skills_3d_modeling_skill_reference_system_usage, _claude_skills_3d_modeling_references_patterns_patterns_reference, _claude_skills_3d_modeling_references_sharp_edges_sharp_edges_reference, _claude_skills_3d_modeling_references_validations_validations_reference [EXTRACTED 1.00]
- **Pre-Export Geometry Validation Checks** — _claude_skills_3d_modeling_references_validations_unapplied_transforms_export, _claude_skills_3d_modeling_references_validations_no_ngon_check, _claude_skills_3d_modeling_references_validations_no_nonmanifold_check, _claude_skills_3d_modeling_references_validations_missing_normals_recalculation, _claude_skills_3d_modeling_references_patterns_export_pipeline [INFERRED 0.85]
- **Sculpt-to-Game-Ready Asset Pipeline** — _claude_skills_3d_modeling_references_patterns_organic_sculpting_workflow, _claude_skills_3d_modeling_references_patterns_retopology_workflow, _claude_skills_3d_modeling_references_patterns_uv_unwrapping_strategy, _claude_skills_3d_modeling_references_patterns_high_to_low_baking, _claude_skills_3d_modeling_references_patterns_lod_creation_strategy, _claude_skills_3d_modeling_references_patterns_export_pipeline [INFERRED 0.85]
- **Material fix-up pipeline for Blender-exported glTF** — virtuve_index_fixmaterial, virtuve_index_fixmaterialonce, virtuve_index_swapmap, virtuve_index_tex, virtuve_index_decor, virtuve_index_canvastex [EXTRACTED 1.00]
- **Walkthrough movement with AABB collision** — virtuve_index_frame, virtuve_index_blocked, virtuve_index_solids, virtuve_index_look, virtuve_index_first_person_controls [EXTRACTED 1.00]

## Communities (8 total, 4 thin omitted)

### Community 2 - "Kitchen Viewer Runtime"
Cohesion: 0.16
Nodes (13): Naujoji virtuve (3D kitchen walkthrough page), blocked(), Evening dusk lighting rig (Sky, low orange sun, warm interior lights), First-person controls (WASD + pointer lock, drag fallback, touch joystick), fixMaterial(), frame() render/movement loop, loadModel(), look() (+5 more)

### Community 3 - "3D Skill Core Principles"
Cohesion: 0.21
Nodes (6): 3D Modeling Sharp Edges Reference, 3D Modeling Skill, Inverted Normals After Mirroring (battle scar), Senior 3D Artist / Technical Artist Persona, omer-metin/skills-for-antigravity (Apache-2.0), 3D Modeling Skill Source Attribution

### Community 4 - "Kitchen Materials and Textures"
Cohesion: 0.33
Nodes (8): canvasTex(), DECOR selected decor textures (oak, sand), Selected decors: U750 ST9 Taupe Grey, H1180 ST37 Natural Halifax Oak, F226 ST78 Sand Beige Titanite, fixMaterialOnce(), speckle(), swapMap(), TEX procedural texture table, kitchen.json (Blender glTF scene, base64-embedded buffer)

### Community 5 - "Ponytail Coding Skill"
Cohesion: 0.33
Nodes (3): Ponytail skill (lazy senior dev mode), Ponytail levels (lite, full, ultra), Shortcut comment convention

## Knowledge Gaps
- **6 isolated node(s):** `omer-metin/skills-for-antigravity (Apache-2.0)`, `3D Modeling Sharp Edges Reference`, `CLAUDE.md (project instructions)`, `Shortcut comment convention`, `Ponytail levels (lite, full, ultra)` (+1 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 12 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `3D Modeling Patterns Reference` connect `Topology, UVs and Baking` to `Export Validation Rules`, `3D Skill Core Principles`, `Modular Assets and Scale`?**
  _High betweenness centrality (0.213) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `UV Unwrapping Strategy` (e.g. with `High to Low Poly Baking` and `Validation: Non-Power-of-Two Texture Dimensions`) actually correct?**
  _`UV Unwrapping Strategy` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `omer-metin/skills-for-antigravity (Apache-2.0)`, `3D Modeling Sharp Edges Reference`, `CLAUDE.md (project instructions)` to the rest of the system?**
  _6 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Why does `3D Modeling Validations Reference` connect `Export Validation Rules` to `Topology, UVs and Baking`, `3D Skill Core Principles`, `Modular Assets and Scale`?**
  _High betweenness centrality (0.111) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `Export Pipeline Standards` (e.g. with `Anti-pattern: Modeling with N-gons` and `Anti-pattern: Exporting with Unapplied Transforms`) actually correct?**
  _`Export Pipeline Standards` has 4 INFERRED edges - model-reasoned connections that need verification._
- **Why does `3D Modeling Skill` connect `3D Skill Core Principles` to `Topology, UVs and Baking`, `Export Validation Rules`?**
  _High betweenness centrality (0.072) - this node is a cross-community bridge._