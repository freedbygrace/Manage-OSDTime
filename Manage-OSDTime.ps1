<#
    .SYNOPSIS
    A brief overview of what your function does
          
    .DESCRIPTION
    Slightly more detailed description of what your function does
          
    .PARAMETER ParameterName
    Your parameter description

    .PARAMETER ParameterName
    Your parameter description

    .PARAMETER ParameterName
    Your parameter description

    .PARAMETER DestinationTimeZoneID
    A valid string. Specify a time zone ID that exists on the current system. Input will be validated against the list of time zones available on the system.
    All date/time operations within this script will converted the current system time to the destination timezone for standardization. That time will then be converted to UTC. The UTC time will then be converted to the WMI format and stored.
          
    .EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -NoProfile -NoLogo -File "%FolderPathContainingScript%\%ScriptName%.ps1"

    .EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -NoProfile -NoLogo -File "%FolderPathContainingScript%\%ScriptName%.ps1" -ScriptParameter "%ScriptParameterValue%"

    .EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -NoProfile -NoLogo -File "%FolderPathContainingScript%\%ScriptName%.ps1" -SwitchParameter
  
    .NOTES
    Any useful tidbits
          
    .LINK
    www.powershellDistrict.com

    .LINK
    https://github.com/Stephanevg/Manage-OSDTime

    .LINK
    http://woshub.com/how-to-set-timezone-from-command-prompt-in-windows/

    .LINK
    https://devblogs.microsoft.com/scripting/powertip-use-powershell-to-retrieve-the-date-and-time-of-the-given-time-zone-id/
#>

[CmdletBinding()]
    Param
        (        	     
            [Parameter(Mandatory=$False)]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({($_ -imatch '^.*\_$')})]
            [String]$OSDVariablePrefix = "CustomOSDInfo_",
            
            [Parameter(Mandatory=$False)]
            [Switch]$Start,

            [Parameter(Mandatory=$False)]
            [String]$OSDVariableName_Start = "$($OSDVariablePrefix)OSDStartTime",

            [Parameter(Mandatory=$False)]
            [Switch]$End,

            [Parameter(Mandatory=$False)]
            [String]$OSDVariableName_End = "$($OSDVariablePrefix)OSDEndTime",
            
            [Parameter(Mandatory=$False)]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({($_ -iin ([System.TimeZoneInfo]::GetSystemTimeZones().ID | Sort-Object))})]
            [String]$DestinationTimeZoneID = "Eastern Standard Time",
            
            [Parameter(Mandatory=$False)]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({($_ -imatch '^[a-zA-Z][\:]\\.*?[^\\]$')})]
            [Alias('LogPath')]
            [System.IO.DirectoryInfo]$LogDir = "$($Env:Windir)\Logs\Software"
        )

#Define Default Action Preferences
    $Script:DebugPreference = 'SilentlyContinue'
    $Script:ErrorActionPreference = 'Stop'
    $Script:VerbosePreference = 'SilentlyContinue'
    $Script:WarningPreference = 'Continue'
    $Script:ConfirmPreference = 'None'
    
#Load WMI Classes
  $Baseboard = Get-WmiObject -Namespace "root\CIMv2" -Class "Win32_Baseboard" -Property * | Select-Object -Property *
  $Bios = Get-WmiObject -Namespace "root\CIMv2" -Class "Win32_Bios" -Property * | Select-Object -Property *
  $ComputerSystem = Get-WmiObject -Namespace "root\CIMv2" -Class "Win32_ComputerSystem" -Property * | Select-Object -Property *
  $OperatingSystem = Get-WmiObject -Namespace "root\CIMv2" -Class "Win32_OperatingSystem" -Property * | Select-Object -Property *

#Retrieve property values
  $OSArchitecture = $($OperatingSystem.OSArchitecture).Replace("-bit", "").Replace("32", "86").Insert(0,"x").ToUpper()

#Define variable(s)
  $DateTimeLogFormat = 'dddd, MMMM dd, yyyy hh:mm:ss tt'  ###Monday, January 01, 2019 10:15:34 AM###
  [ScriptBlock]$GetCurrentDateTimeLogFormat = {(Get-Date).ToString($DateTimeLogFormat)}
  $DateTimeFileFormat = 'yyyyMMdd_hhmmsstt'  ###20190403_115354AM###
  [ScriptBlock]$GetCurrentDateTimeFileFormat = {(Get-Date).ToString($DateTimeFileFormat)}
  [System.IO.FileInfo]$ScriptPath = "$($MyInvocation.MyCommand.Definition)"
  [System.IO.FileInfo]$ScriptLogPath = "$($LogDir.FullName)\$($ScriptPath.BaseName)_$($GetCurrentDateTimeFileFormat.Invoke()).log"
  [System.IO.DirectoryInfo]$ScriptDirectory = "$($ScriptPath.Directory.FullName)"
  [System.IO.DirectoryInfo]$FunctionsDirectory = "$($ScriptDirectory.FullName)\Functions"
  [System.IO.DirectoryInfo]$ModulesDirectory = "$($ScriptDirectory.FullName)\Modules"
  $IsWindowsPE = Test-Path -Path 'HKLM:\SYSTEM\ControlSet001\Control\MiniNT' -ErrorAction SilentlyContinue

#Log any useful information
  $LogMessage = "IsWindowsPE = $($IsWindowsPE.ToString())`r`n"
  Write-Verbose -Message "$($LogMessage)" -Verbose

  $LogMessage = "Script Path = $($ScriptPath.FullName)`r`n"
  Write-Verbose -Message "$($LogMessage)" -Verbose
  
  $LogMessage = "Script Directory = $($ScriptDirectory.FullName)`r`n"
  Write-Verbose -Message "$($LogMessage)" -Verbose
	
#Log task sequence variables if debug mode is enabled within the task sequence
  Try
    {
        [System.__ComObject]$TSEnvironment = New-Object -ComObject "Microsoft.SMS.TSEnvironment"
              
        If ($TSEnvironment -ine $Null)
          {
              $IsRunningTaskSequence = $True
          }
    }
  Catch
    {
        $IsRunningTaskSequence = $False
    }

#Start transcripting (Logging)
  Try
    {
        If ($LogDir.Exists -eq $False) {[System.IO.Directory]::CreateDirectory($LogDir.FullName)}
        Start-Transcript -Path "$($ScriptLogPath.FullName)" -IncludeInvocationHeader -Force -Verbose
    }
  Catch
    {
        If ([String]::IsNullOrEmpty($_.Exception.Message)) {$ExceptionMessage = "$($_.Exception.Errors.Message)"} Else {$ExceptionMessage = "$($_.Exception.Message)"}
          
        $ErrorMessage = "[Error Message: $($ExceptionMessage)][ScriptName: $($_.InvocationInfo.ScriptName)][Line Number: $($_.InvocationInfo.ScriptLineNumber)][Line Position: $($_.InvocationInfo.OffsetInLine)][Code: $($_.InvocationInfo.Line.Trim())]"
        Write-Error -Message "$($ErrorMessage)"
    }

#Log any useful information
  $LogMessage = "IsWindowsPE = $($IsWindowsPE.ToString())"
  Write-Verbose -Message "$($LogMessage)" -Verbose

  $LogMessage = "Script Path = $($ScriptPath.FullName)"
  Write-Verbose -Message "$($LogMessage)" -Verbose

  $DirectoryVariables = Get-Variable | Where-Object {($_.Value -ine $Null) -and ($_.Value -is [System.IO.DirectoryInfo])}
  
  ForEach ($DirectoryVariable In $DirectoryVariables)
    {
        $LogMessage = "$($DirectoryVariable.Name) = $($DirectoryVariable.Value.FullName)"
        Write-Verbose -Message "$($LogMessage)" -Verbose
    }

#region Import Dependency Modules
$Modules = Get-Module -Name "$($ModulesDirectory.FullName)\*" -ListAvailable -ErrorAction Stop 

$ModuleGroups = $Modules | Group-Object -Property @('Name')

ForEach ($ModuleGroup In $ModuleGroups)
  {
      $LatestModuleVersion = $ModuleGroup.Group | Sort-Object -Property @('Version') -Descending | Select-Object -First 1
      
      If ($LatestModuleVersion -ine $Null)
        {
            $LogMessage = "Attempting to import dependency powershell module `"$($LatestModuleVersion.Name) [Version: $($LatestModuleVersion.Version.ToString())]`". Please Wait..."
            Write-Verbose -Message "$($LogMessage)" -Verbose
            Import-Module -Name "$($LatestModuleVersion.Path)" -Global -DisableNameChecking -Force -ErrorAction Stop
        }
  }
#endregion

#region Dot Source Dependency Scripts
#Dot source any additional script(s) from the functions directory. This will provide flexibility to add additional functions without adding complexity to the main script and to maintain function consistency.
  Try
    {
        If ($FunctionsDirectory.Exists -eq $True)
          {
              [String[]]$AdditionalFunctionsFilter = "*.ps1"
        
              $AdditionalFunctionsToImport = Get-ChildItem -Path "$($FunctionsDirectory.FullName)" -Include ($AdditionalFunctionsFilter) -Recurse -Force | Where-Object {($_ -is [System.IO.FileInfo])}
        
              $AdditionalFunctionsToImportCount = $AdditionalFunctionsToImport | Measure-Object | Select-Object -ExpandProperty Count
        
              If ($AdditionalFunctionsToImportCount -gt 0)
                {                    
                    ForEach ($AdditionalFunctionToImport In $AdditionalFunctionsToImport)
                      {
                          Try
                            {
                                $LogMessage = "Attempting to dot source dependency script `"$($AdditionalFunctionToImport.Name)`". Please Wait...`r`n`r`nScript Path: `"$($AdditionalFunctionToImport.FullName)`""
                                Write-Verbose -Message "$($LogMessage)" -Verbose
                          
                                . "$($AdditionalFunctionToImport.FullName)"
                            }
                          Catch
                            {
                                $ErrorMessage = "[Error Message: $($_.Exception.Message)]`r`n`r`n[ScriptName: $($_.InvocationInfo.ScriptName)]`r`n[Line Number: $($_.InvocationInfo.ScriptLineNumber)]`r`n[Line Position: $($_.InvocationInfo.OffsetInLine)]`r`n[Code: $($_.InvocationInfo.Line.Trim())]"
                                Write-Error -Message "$($ErrorMessage)" -Verbose
                            }
                      }
                }
          }
    }
  Catch
    {
        $ErrorMessage = "[Error Message: $($_.Exception.Message)]`r`n`r`n[ScriptName: $($_.InvocationInfo.ScriptName)]`r`n[Line Number: $($_.InvocationInfo.ScriptLineNumber)]`r`n[Line Position: $($_.InvocationInfo.OffsetInLine)]`r`n[Code: $($_.InvocationInfo.Line.Trim())]"
        Write-Error -Message "$($ErrorMessage)" -Verbose            
    }
#endregion

#Perform script action(s)
  Try
    {                          
        #Tasks defined within this block will only execute if a task sequence is running
          If (($IsRunningTaskSequence -eq $True))
            {    
                $OriginalTimeZone = Get-TimeZone -Verbose
    
                $LogMessage = "The current time zone set in the operating system is `"$($OriginalTimeZone.DisplayName)`""
                Write-Verbose -Message "$($LogMessage)" -Verbose
                                      
                If ($Start.IsPresent -eq $True)
                  {
                      $LogMessage = "Attempting to convert the current system time to `"$($DestinationTimeZoneID)`""
                      Write-Verbose -Message "$($LogMessage)" -Verbose
                  
                      $ConvertedSystemDateTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), ($DestinationTimeZoneID))
                      
                      $LogMessage = "Attempting to convert the current system time that was converted from `"$($OriginalTimeZone.DisplayName)`" to `"$($DestinationTimeZoneID)`" into the `"Universal Time Coordinated (UTC)`" format."
                      Write-Verbose -Message "$($LogMessage)" -Verbose
                      
                      $ConvertedSystemDateTimeUTC = $ConvertedSystemDateTime.ToUniversalTime()
                  
                      $StartTime = $ConvertedSystemDateTimeUTC
                      
                      $TSEnvironment.Value($OSDVariableName_Start) = $StartTime    
          
                      $LogMessage = "Task sequence start time set to $($TSEnvironment.Value($OSDVariableName_Start)) (Universal Time Coordinated (UTC))"
                      Write-Verbose -Message "$($LogMessage)" -Verbose   
                  }
                ElseIf ($End.IsPresent -eq $True)
                  { 
                      $StartTime = $TSEnvironment.Value($OSDVariableName_Start)
                
                      If ([String]::IsNullOrEmpty($StartTime) -eq $True)
                        {
                            $WarningMessage = "Could not find the Task sequence variable `"$($OSDVariableName_Start)`". Be sure that the variable has been set PRIOR this step by using the -START switch"
                            Write-Warning -Message "$($WarningMessage)" -Verbose
                        }
                      Else
                        {                
                            $LogMessage = "The currently running task sequence was started at $($StartTime) (Universal Time Coordinated (UTC))"
                            Write-Verbose -Message "$($LogMessage)" -Verbose
                
                            $LogMessage = "Attempting to convert the current system time to `"$($DestinationTimeZoneID)`""
                            Write-Verbose -Message "$($LogMessage)" -Verbose
                  
                            $ConvertedSystemDateTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), ($DestinationTimeZoneID))
                      
                            $LogMessage = "Attempting to convert the current system time that was converted from `"$($OriginalTimeZone.DisplayName)`" to `"$($DestinationTimeZoneID)`" into the `"Universal Time Coordinated (UTC)`" format."
                            Write-Verbose -Message "$($LogMessage)" -Verbose
                      
                            $ConvertedSystemDateTimeUTC = $ConvertedSystemDateTime.ToUniversalTime()
                        
                            $EndTime = $ConvertedSystemDateTimeUTC
                            
                            $TSEnvironment.Value($OSDVariableName_End) = $EndTime
                                
                            $LogMessage = "Task sequence end time set to $($TSEnvironment.Value($OSDVariableName_End)) (Universal Time Coordinated (UTC))"
                            Write-Verbose -Message "$($LogMessage)" -Verbose
                        }
                  }     
            }
    
        #Tasks defined here will execute whether only if a task sequence is not running
          If ($IsRunningTaskSequence -eq $False)
            {
                $WarningMessage = "There is no task sequence running.`r`n"
                Write-Warning -Message "$($WarningMessage)" -Verbose
            }
                        
        #Stop transcripting (Logging)
          Try
            {
                Stop-Transcript -Verbose
            }
          Catch
            {
                If ([String]::IsNullOrEmpty($_.Exception.Message)) {$ExceptionMessage = "$($_.Exception.Errors.Message)"} Else {$ExceptionMessage = "$($_.Exception.Message)"}
          
                $ErrorMessage = "[Error Message: $($ExceptionMessage)][ScriptName: $($_.InvocationInfo.ScriptName)][Line Number: $($_.InvocationInfo.ScriptLineNumber)][Line Position: $($_.InvocationInfo.OffsetInLine)][Code: $($_.InvocationInfo.Line.Trim())]"
                Write-Error -Message "$($ErrorMessage)"
            }
    }
  Catch
    {
        If ([String]::IsNullOrEmpty($_.Exception.Message)) {$ExceptionMessage = "$($_.Exception.Errors.Message -Join "`r`n`r`n")"} Else {$ExceptionMessage = "$($_.Exception.Message)"}
          
        $ErrorMessage = "[Error Message: $($ExceptionMessage)]`r`n`r`n[ScriptName: $($_.InvocationInfo.ScriptName)]`r`n[Line Number: $($_.InvocationInfo.ScriptLineNumber)]`r`n[Line Position: $($_.InvocationInfo.OffsetInLine)]`r`n[Code: $($_.InvocationInfo.Line.Trim())]`r`n"
        Throw "$($ErrorMessage)"
    }
