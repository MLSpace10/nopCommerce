[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '_initialize-result.ps1')

$failureHtml = @'
<html>
  <div class="message-error validation-summary-errors">
    <ul><li>Setup failed: CommerceEngineeringLab could not be created. Password=test-secret</li></ul>
  </div>
  <form id="restart-form" method="post"></form>
</html>
'@

if (Test-NopInstallationResponseSuccessful -Html $failureHtml) {
    throw 'An installation error page containing restart-form was incorrectly accepted as successful.'
}

$errorText = Get-NopInstallationErrorText -Html $failureHtml -SensitiveValues @('test-secret')
if ($errorText -notmatch 'CommerceEngineeringLab could not be created' -or $errorText -match 'test-secret') {
    throw 'The installation error text was not extracted and sanitized as expected.'
}

$successHtml = @'
<html>
  <script>
    $.ajax({
      url: "/install/restartapplication",
      complete: function () {
        window.location.replace('/');
      }
    });
  </script>
  <form id="restart-form" method="post"></form>
</html>
'@

if (-not (Test-NopInstallationResponseSuccessful -Html $successHtml)) {
    throw 'An installation response containing the successful RestartUrl block was rejected.'
}

Write-Host 'Initializer installation result detection checks passed.'
