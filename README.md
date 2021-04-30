# cwmApi
Connectwise Manage API PowerShell

## Introduction
This module facilitates interaction with the ConnectWise Manage REST API via PowerShell. It is designed to make access simple with picklists and a built-in entity explorer, and also to grow with the ConnectWise Manage API. PickLists and endpoints are dynamically generated from the API JSON file, so updates are fast.

## Changelog
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
