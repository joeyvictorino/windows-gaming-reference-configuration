# Benchmark methodology

Record Windows build, driver, firmware, power source, OEM mode, resolution/refresh, game version/preset, shader state and active downloads.

Minimum:
1. reboot
2. settle 3 minutes
3. confirm no download/update workload
4. run identical workload at least three times
5. report individual runs and median
6. capture average FPS, 1% low and frame-time data when available
7. treat changes inside normal run-to-run variance as no change

Recommended: GPU-bound DX12, CPU-sensitive game, DX11, Vulkan if available, 3DMark reference, and at least one Xbox/Game Pass game.

A valid result can be: **no meaningful FPS change, with a quieter login and no compatibility regression**.
