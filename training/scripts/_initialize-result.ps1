function Test-NopInstallationResponseSuccessful {
    param([Parameter(Mandatory)][string]$Html)

    return $Html -match '(?i)/install/restartapplication' -and
        $Html -match '(?i)window\.location\.replace\s*\('
}

function Get-NopInstallationErrorText {
    param(
        [Parameter(Mandatory)][string]$Html,
        [string[]]$SensitiveValues = @()
    )

    $patterns = @(
        '(?is)<div\b[^>]*class\s*=\s*["''][^"'']*(?:validation-summary-errors|message-error)[^"'']*["''][^>]*>(?<message>.*?)</div>',
        '(?is)<ul\b[^>]*class\s*=\s*["''][^"'']*validation-summary-errors[^"'']*["''][^>]*>(?<message>.*?)</ul>',
        '(?is)<span\b[^>]*class\s*=\s*["''][^"'']*field-validation-error[^"'']*["''][^>]*>(?<message>.*?)</span>'
    )

    foreach ($pattern in $patterns) {
        $match = [regex]::Match($Html, $pattern)
        if (-not $match.Success) {
            continue
        }

        $text = $match.Groups['message'].Value -replace '(?is)<script\b.*?</script>', ' '
        $text = $text -replace '(?s)<[^>]+>', ' '
        $text = [Net.WebUtility]::HtmlDecode($text)
        $text = ($text -replace '\s+', ' ').Trim()
        if ([string]::IsNullOrWhiteSpace($text)) {
            continue
        }

        foreach ($sensitiveValue in $SensitiveValues) {
            if (-not [string]::IsNullOrEmpty($sensitiveValue)) {
                $text = $text.Replace($sensitiveValue, '***')
            }
        }

        $text = $text -replace '(?i)\b(password|pwd)\s*=\s*[^;\s<]+', '$1=***'
        $text = $text -replace '(?i)\b(api[-_ ]?key|TRAINING_API_KEY)\s*[:=]\s*[^;\s<]+', '$1=***'

        return $text.Substring(0, [Math]::Min(500, $text.Length))
    }

    return 'The installation response did not include a validation error message.'
}
