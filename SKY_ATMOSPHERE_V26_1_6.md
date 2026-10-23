# Aurora Viva V26.1.6 — Sky & Atmosphere Fix

Built on V26.1.5 (Performance Core). No changes to celestial atlas, planets, black hole, shadows, or water materials.

Changes:
- Fixed world-height ray intersections for `CLOUD_STYLE=2` volumetric clouds. The layer no longer moves vertically with the camera.
- Volumetric cloud base 480 (world Y) and thickness 240 by default, configurable in Iris > Sky > Clouds. Prior effective layer was 1000–1500 relative to the camera.
- Rays that do not intersect clouds skip all 12 sampling steps. Supports climbing into the layer and looking upward from inside or above.
- DH-only distant terrain fade into the computed sky starts at 78% of DH render distance by default, configurable in Iris > Distant Horizons & Voxy. Reduces rectangular geometry cutoff at long range; far LOD detail is intentionally softened. Does not change close-range geometry.
- Main and water/deferred passes synchronized; source module and expanded program synchronized.

LIMITATIONS:
- This is a source/structural validation, not a runtime Iris or driver compile test.
- The sky-only cloud render path does not yet draw clouds in front of nearby terrain when the camera is above their layer. That requires a depth-aware volumetric composite pass.
- Visible square horizon can also come from DH's own LOD boundary or terrain provider. Fog only hides it; does not alter DH geometry.
- CLOUD_STYLE 3 uses a separate block-cloud system and its altitude was not changed in this patch.

TEST:
1. With Iris 1.11.7 + DH 64 and Sodium 8 chunks, stand at Y 200, 400, 550 and compare the cloud base and horizon. Avoid assuming that the clouds should be visible while looking down across terrain from above them.
2. Try DH Horizon Fade Start=0.93 vs 0.70. At 0.93 detail is preserved; at 0.70 the square edge should be more hidden.
3. Compare the sky, moon, black hole, and stars against V26.1.5 for visual regressions.
4. Do not commit without in-game validation.
