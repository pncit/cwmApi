function Get-CwmApiEndpoints {
    Param(
        [parameter(Mandatory=$true)]
        [validateNotNullorEmpty()]
        [string]$matches
    )

    ( $Script:cwmApiQueries | Where-Object { $_.endpoint -Like "*$($matches)*" } ).Endpoint
}