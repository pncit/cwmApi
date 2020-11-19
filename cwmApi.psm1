$Sources  = @(Get-ChildItem -Path $PSScriptRoot\Functions\*.ps1 -ErrorAction SilentlyContinue)
foreach ($Source in @($Sources))
{
    try {
        . $Source.FullName
    }
    catch {
        Write-Error -Message "Failed to import function $($Source.FullName): $_"
    }
}