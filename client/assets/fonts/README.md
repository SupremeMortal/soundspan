# Bundled fonts

The client bundles its fonts as assets and never downloads a font at runtime. Each font is licensed under the SIL Open Font License, Version 1.1; its licence text is in `assets/licenses/fonts/<Family>.txt`, which `tool/license_audit.dart` requires for every file in this directory.

| File | Family | Source | Commit | SHA-256 | Licence |
|---|---|---|---|---|---|
| `Montserrat-VariableFont_wght.ttf` | Montserrat (upright, variable `wght` axis) | [`ofl/montserrat/Montserrat[wght].ttf`](https://github.com/google/fonts/blob/29b4ec6df2522a8aee279414b78a07910b065874/ofl/montserrat/Montserrat%5Bwght%5D.ttf) in `google/fonts` | `29b4ec6df2522a8aee279414b78a07910b065874` | `0f7b311b2f3279e4eef9b2f968bcdbab6e28f4daeb1f049f4f278a902bcd82f7` | SIL Open Font License 1.1 (`assets/licenses/fonts/Montserrat.txt`) |
| `TurretRoad-ExtraBold.ttf` | Turret Road, weight 800 (wordmark only) | [`ofl/turretroad/TurretRoad-ExtraBold.ttf`](https://github.com/google/fonts/blob/29b4ec6df2522a8aee279414b78a07910b065874/ofl/turretroad/TurretRoad-ExtraBold.ttf) in `google/fonts`; byte-identical to `frontend/assets/fonts/TurretRoad-ExtraBold.ttf` | `29b4ec6df2522a8aee279414b78a07910b065874` | `566338de973b47357317a9af96fe5e99c0fefe3d4e7707780bd78e8090c652b8` | SIL Open Font License 1.1 (`assets/licenses/fonts/TurretRoad.txt`) |

To replace a font, download it from the source at a new commit, update the commit and checksum here, and compare the licence text with the `OFL.txt` beside it.
