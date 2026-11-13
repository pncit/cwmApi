# cwmApi

Connectwise Manage API PowerShell

## Introduction

This module facilitates interaction with the ConnectWise Manage REST API via PowerShell. It is designed to make access simple with picklists and a built-in entity explorer, and also to grow with the ConnectWise Manage API. PickLists and endpoints are dynamically generated from the API JSON file, so updates are fast.

## Examples

### Select API version 2026.11

    Import-Module cwmApi -Force
    Initialize-CwmApiEnvironment -company $CwmCompany -publicKey $CwmApiPublicKey -privateKey $CwmApiPrivateKey -clientId $CwmApiClientId -version '2026.11'

When `-version` is omitted, the module selects the company's API version. To use a local catalog, pass `-structureXmlFile ./data/cwmApi_2026.11.xml` instead of `-version`.

The 2026.11 catalog includes company service templates, template tasks and resources, ticket contact authentication, custom field information, and the other endpoints in the supplied specification. Use `Get-CwmApiEndpoints -matches 'serviceTemplates'` to explore paths and `-endpointDisambiguationString` when multiple paths match an entity.

New path parameters are available for expense report attachments and standard reports:

    Get-CwmApiEntity -Entity ExpenseReports -id 123 -memberRecId 456
    New-CwmApiEntity -Entity Reports -reportlink 'My Report' -bodyJson '{}'

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

## Catalog generation and validation

Generating catalogs requires PowerShell 7 or later to preserve JSON keys that differ only by case. The module still supports Windows PowerShell 5.1 and PowerShell Core.

    . ./functions/Set-CwmApiStructure.ps1
    Set-CwmApiStructure -jsonFile ./data/cwmApi_2026.11.json -xmlFile ./data/cwmApi_2026.11.xml

Run the offline validation from the repository root. It checks the catalog, version selection, entity parameters, and outgoing requests without using API credentials:

    ./tests/Validate-CwmApi.ps1

## Changelog

- 1.6.2
    - Added support for API version 2026.11 and its generated endpoint catalog.
    - Preserved paths that differ only by case during catalog generation (requires PowerShell 7 or later).
    - Added `memberRecId` to `Get-CwmApiEntity` and `reportlink` to `New-CwmApiEntity`.
- 1.6.1
    - Removed duplicate addition of the UseBasicParsing parameter to Invoke-WebRequest
- 1.6.0
    - Added 'allowInsecureRedirect' switch for New-CwmApiEntity cmdlet (Invoke-WebRequest throws an insecure redirection error when the location header is http, even when the response is 201 and no redirection is impending)
- 1.5.1
    - Fixed the broken logic around the endpointDisambiguationStringInclusive boolean
- 1.5.0
    - Added the 'endpointDisambiguationStringInclusive boolean to allow excluding search terms
- 1.4.3
    - Updated with support for 2025.1 release
- 1.4.2
    - Fixed code that was limiting some queries to 1000 total responses
- 1.4.1
    - Updated with support for 2022.1 release
- 1.4.0
    - Added New-CwmApiDocument to upload documents
- 1.3.2
    - Added random suffix to temp api structure xml file to prevent collisions when multiple sessions are being invoked simultaneously
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
