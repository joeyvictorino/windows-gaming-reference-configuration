# Lenovo Legion 9 16IRX8 reference profile

Initial validation hardware:

- machine type 83AG
- Intel Core i9-13980HX
- NVIDIA GeForce RTX 4090 Laptop GPU, 16 GB
- 3200 × 2000 high-refresh panel
- Lenovo Vantage controls
- Windows 11 25H2

WGRC deliberately does not call undocumented Lenovo embedded-controller or hidden firmware interfaces.

For gaming while plugged in, use Lenovo's supported Performance thermal mode, confirm the intended high refresh rate and use supported Lenovo/NVIDIA graphics-mode controls.

`Audit` and `Verify` report Secure Boot but do not change UEFI firmware. Before enabling Secure Boot, confirm recovery-key access and UEFI boot state.

GPU overclocking/undervolting is a separate measured commissioning exercise, not part of generic Apply.
