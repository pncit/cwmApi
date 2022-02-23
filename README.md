# cwmApi

Connectwise Manage API PowerShell

## Introduction

This module facilitates interaction with the ConnectWise Manage REST API via PowerShell. It is designed to make access simple with picklists and a built-in entity explorer, and also to grow with the ConnectWise Manage API. PickLists and endpoints are dynamically generated from the API JSON file, so updates are fast.

## Examples

### Create Ticket with a Configuration

    Import-Module cwmApi -Force
    Initialize-CwmApiEnvironment -company $CwmCompany -publicKey $CwmApiPublicKey -privateKey $CwmApiPrivateKey -clientId $CwmApiClientId
    $CwmConfiguration = Get-CwmApiEntity -Entity Configurations -conditions 'name="Server01"' -fields "company/id,site/id,id,name"
    $TicketInfo = @{
        "company" = @{
            "id" = $CwmConfiguration.company.id
        }
        "site" = @{
            "id" = $CwmConfiguration.site.id
        }
        "status" = @{
            "id" = $NewNoEmailId
        }
        "summary" = "Reboot error on $($CwmConfiguration.Name)"
        "initialDescription" =  ( "Failed to reboot $($CwmConfiguration.Name) as scheduled." )
    } | ConvertTo-Json
    $Ticket = New-CwmApiEntity -Entity Tickets -BodyJson $TicketInfo
    $ConfigurationBody = @{
        "id" = $CwmConfiguration.id
    } | ConvertTo-Json
    New-CwmApiEntity -Entity Tickets -parentId $Ticket.id -BodyJson $ConfigurationBody -endpointDisambiguationString "configurations" | Out-Null
    
## Changelog

- 1.3.1
    - Fixed typo so that all GET requests where PageSize is not specified default to 1000
- 1.3.0
    - Added 'getRawResponse' switch parameter to New-CwmApiResponse that allows user to bystep any processing of API response (useful for file downloads)
- 1.2.5
    - Added the 'endpointDisambiguationString' parameter to Edit-CwmApiEntity
- 1.2.4
    - Updated with support for 2021.3 release
- 1.2.3
    - Fixed how the module passes version requests to the API
- 1.2.2
    - Converted warning message to verbose message when initializing sessions so that fully automated systems do not have to handle output
- 1.2.1
    - Added clean verbose and debug messaging
    - Added the 'endpointDisambiguationString' parameter to all request functions
- 1.1.7
    - Replaced 'projectOrService' parameter in New-CwmApiEntity with a more generic 'endpointDisambiguationString' parameter that allows the user to pass a search string to disambiguate endpoints (e.g. /service/tickets/{parentId}/attachChildren vs /service/tickets/{parentId}/configurations)
- 1.1.6
    - Added 'projectOrService' parameter to New-CwmApiEntity to distinguish between project tickets and service tickets when create a new TicketNotes item
- 1.1.5
    - Updated with support for 2021.2 release
- 1.1.4
    - Updated with support for 2021.1 release
- 1.1.2
    - Added debug messaging
    - Enhanced Edit-CwmApiEntity to allow 'value' to have multiple types
    - Fixed issue with non-GET requests having ?pageSize added to them
- 1.1.1
    - Set all Invoke-WebRequest instances to -UseBasicParsing for maximum compatibility
- 1.1.0
    - First major release
