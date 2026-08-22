@{
    Severity = @('Error','Warning')
    ExcludeRules = @(
        # WGRC uses Write-Host deliberately for an operator-oriented CLI,
        # while state is separately recorded as JSON/transcript.
        'PSAvoidUsingWriteHost'
    )
}
