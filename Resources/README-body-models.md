# Injection Tracker 3D Body Models

The injection-site tracker in `Sources/Views/Protocol/InjectionTrackerView.swift`
loads its anatomical mesh from a bundled USDZ.

## Files

- `body.usdz` — realistic male anatomical mesh (required)
  - Source: CGTrader, "Realistic Human Nude Male full body Free"
  - ~10 MB, ~120k tris, Z-up Blender export, eyes/teeth included.
- `body_female.obj` + `body_female.mtl` — female mannequin mesh
  - Source: CGTrader "Female body dummy — Low-poly" by the same
    author pipeline (Blender 3.3 export, originally named `maneken.*`).
  - ~2.4 MB total, 17k verts / 17k tris, **Y-up** (unlike the male
    USDZ), T-pose, 1.80m tall, eyes included.
  - Cleaner/lower-poly than the male mesh but matches on scale and
    proportions, and has valid face topology (no sparse-face issues).
  - The MTL is trivial (solid gray) — our loader overrides it with
    a PBR skin material anyway.
  - **To upgrade to a higher-fidelity female mesh later:** replace
    both files (keep the `body_female.` prefix) with any OBJ/USDZ
    pair; the loader auto-detects up-axis from the bbox and handles
    both Y-up and Z-up meshes.

## How the loader uses these

`BodyMeshLoader.loadNode(gender:)` in `InjectionTrackerView.swift`:

1. Resolves a bundled resource by gender: `body` (male) or
   `body_female` (female), trying `.usdz` first then `.obj`.
2. Strips non-body prims (reference cubes, export cameras, lights)
   via node-name allowlist.
3. **Auto-detects up-axis from the bounding box**: whichever of X, Y,
   or Z has the largest extent is "up" (humans are always tallest in
   their up-axis). If Z is tallest → applies -90° X rotation to
   convert to Y-up. If Y is already tallest → no rotation.
4. Re-centers so feet sit on y=0 and the body is centered on x=0, z=0.
5. Applies a single consistent PBR skin material.

If a requested file can't load, the loader falls back to the other
gender's mesh so the tracker never goes blank.

## Coordinate space after loading

For both meshes (and used by `InjectionZone` pin positions):

```
Y: 0 (feet)  →  ~1.80 (head)
X: -0.45 (left)  →  +0.45 (right)
Z: -0.16 (back)  →  +0.16 (front, toward camera)
```

Pins are placed ~2 cm outside the body surface so they render
visibly while still reading as "attached" to the right landmark.

## Legacy files

`body.obj` and `body.glb` are legacy exports that were already in
Resources from a prior attempt. They're not used by the current
loader. They can be deleted to shrink the bundle (~15 MB combined)
once we're sure nothing else references them.
