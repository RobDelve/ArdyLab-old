﻿#requires -Version 4.0

Configuration LabJoinDomain
{
  param
  (
    [Parameter(Mandatory)]             
    [string]
    $NodeName,

    [Parameter(Mandatory)]             
    [string]
    $DomainName,

    [Parameter(Mandatory)]             
    [pscredential]
    $DomainJoinCredential,

    [Parameter(Mandatory)]             
    [ipaddress]
    $DnsIPAddress,

    [Parameter()]             
    [string]
    $DnsInterfaceAlias = 'ethernet',

    [Parameter()]             
    [string]
    $JoinOU
  )
    
  Import-DscResource -ModuleName xActiveDirectory, xNetworking, xComputerManagement

  xDNSServerAddress SetDnsServer
  {
    Address = $DnsIPAddress
    InterfaceAlias = $DnsInterfaceAlias
    AddressFamily = 'IPv4'
  }

  xWaitForADDomain $DomainName
  {
    DomainName = $DomainName
    RetryIntervalSec = 20
    RetryCount = 50
    DependsOn = '[xDNSServerAddress]SetDnsServer'
  }

  xComputer JoinDomain
  {
    Name = $NodeName
    DomainName = $DomainName
    Credential = $DomainJoinCredential
    #
    JoinOU = $JoinOU
    DependsOn = "[xWaitForADDomain]$($DomainName)"
  }
}