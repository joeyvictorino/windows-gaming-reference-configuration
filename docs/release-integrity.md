# Release integrity

WGRC release archives are designed to be independently verifiable.

## SHA-256

Every tagged release produces:

```text
windows-gaming-reference-configuration-vX.Y.Z.zip
windows-gaming-reference-configuration-vX.Y.Z.zip.sha256
```

Verify with Windows PowerShell:

```powershell
Get-FileHash .\windows-gaming-reference-configuration-vX.Y.Z.zip -Algorithm SHA256
```

Compare the result with the `.sha256` file attached to the same release.

## GitHub artifact attestation

The release workflow uses GitHub artifact attestations to bind the release ZIP to the repository, commit and workflow that produced it.

For a public repository, GitHub uses signed provenance with its attestation/Sigstore infrastructure.

Users with GitHub CLI can verify the attestation against the repository.

## PowerShell code signing

WGRC scripts are not represented as Microsoft-signed code.

The author's former Microsoft employment does not confer a Microsoft code-signing identity.

Until WGRC has its own appropriate code-signing certificate, trust comes from:

- source review
- tagged source
- deterministic release workflow
- SHA-256
- GitHub build provenance
- CI
- minimal privileged behavior

That boundary is intentional and should remain explicit.
