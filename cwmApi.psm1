$Sources  = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue) + @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)
foreach ($Source in @($Sources))
{
    try {
        . $Source.FullName
    }
    catch {
        Write-Error -Message "Failed to import function $($Source.FullName): $_"
    }
}