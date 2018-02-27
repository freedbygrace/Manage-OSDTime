<#
.SYNOPSIS
	<! To get the lastest version and help of this script, use .\Manage-OSDTime.ps1 -Online !>
	
	This script will set and / get the OSD task sequence execution time with the option of tattooing it's value.
    It is recommended to use the second script New-OSDTattoo.ps1 to tattoo the execution time. (but not mandatory) 
   
.DESCRIPTION 
    The script works in 2 parts:
        Part1: Setting the start time
            1) Set this script as one of your first task sequence step (It MUST be after hard drive formating step) using the -Start Parameter
        Part2:
            1) Get the previous time setted.
            2) Calculates the time difference.
            3a)Either writes to registry (if -tattoo switch is specified)
            3b)If the -tattoo switch is omitted,it will creates a TS variable called PSDistrict_OSDInstallTime which can be easily read by the New-OSDTattoo.ps1
                (This be used to be tattooed in WMI / Registry / Environment Variable using the New-OSDTattoo.ps1 script from PowerShellDistrict).Recommend approch.
        

.PARAMETER Start
    Start the time recording process.

.PARAMETER End
    End the time recording process.

.PARAMETER Tattoo
    Specify if it should be tattooed. (Registry is the only option).
    For more tattoo possibilities, look for New-OSDTattoo.ps1 on PowershellDistrict.com

.PARAMETER Root
    Specify the registry root hvye name of the tattoo location.
    If is inexisting, it will be created.

.EXAMPLE
    Will start the time recording process

    Manage-OSDTime.ps1 -Start

.EXAMPLE
    Will end the time recording process. call the New-OsdTattoo.ps1 right after this task sequence step.

    Manage-OSDTime.ps1 -end


.NOTES
	-Author: Stéphane van Gulick
	-Email: stephanevg@powershelldistrict.com
	-CreationDate: 12.01.2014
	-LastModifiedDate: 04.14.2015
	-Version: 2.1
    -History:

    2.1 ; 05.08.2015 ; Minor fixes.
    2.0 ; 04.14.2015 ; Published Manage-OSDTime.ps1 (included basic tattooing).

.LINK
	www.powershellDistrict.com

.LINK
	http://social.technet.microsoft.com/profile/st%C3%A9phane%20vg/
	
#>
[CmdletBinding(
        HelpURI='http://powershelldistrict.com/sccm-how-to-measure-task-sequence-execution-time/'
    )]
Param(
    [switch]$Start,
    [Switch]$End,
    [String]$Root ="OsBuildInfo",
    [switch]$Tattoo
)

begin {
Function New-RegistryItem {
<#
.SYNOPSIS
	Set's a registry item.
   
.DESCRIPTION 
    Set's a registry item in a specefic hvye.
	
	
.PARAMETER RegistryPath
    Specefiy the registry path.
    Default it is in HKLM:SOFTWARE\Company\ hyve.
    /!\Important note /!\
    Powershell requires that the following registry format is respected :
    "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" <-- the "HKLM:" is important and CANNOT be "HKEY_LOCAL_MACHINE" (notice the ':' also!!).


.PARAMETER RegistryString
    This parameter will is used in order to give the name to the registry string that is needed to be tatooted and that will contain information that can later be reported on through SCCM.
    ex : DisplayName
    ex : InstallDate
    Use the parameter "RegistryValue" to give a value to the "registryString".

.PARAMETER RegistryValue
    This parameter is used in order to give a value to a registry string that is already existing or has been previously created.
    example : a date for a registry string called "InstalledDate".
    
.Example
     New-RegistryItem -RegistryString PowerShellDistrictURL -RegistryValue "www.PowerShellDistrict.com"

.NOTES
	-Author: Stéphane van Gulick
	-Email : 
	-CreationDate: 12.01.2014
	-LastModifiedDate: 12.01.2014
	-Version: 1.0
	
#>



    [cmdletBinding()]
    Param(


        [Parameter(Mandatory=$false)]
        [string]$RegistryPath = "HKLM:SOFTWARE\",

        [Parameter(Mandatory=$true)]
        [string]$RegistryString,

        [Parameter(Mandatory=$true)]
        [string]$RegistryValue
        
    )
    begin{

    }
    Process{
    
            ##Creating the registry node
            if (!(test-path $RegistryPath)){
                write-verbose "Creating the registry node at : $($RegistryPath)."
                try{
                    if ($RegistryPath -ne "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"){
                        New-Item -Path $RegistryPath -force -ErrorAction stop | Out-Null
                       }else{
                        write-verbose "The registry path that is tried to be created is the uninstall string.HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\."
                        write-verbose "Creating this here would have as consequence to erase the whole content of the Uninstall registry hive."
                        
                        exit 
                       }
                    }
                catch [System.Security.SecurityException] {
                    write-warning "No access to the registry. Please launch this function with elevated privileges."
                }
                catch{
                    log-message "An unknowed error occured : $_ "
                }
            }
            else{
                write-verbose "The registry hyve already exists at $($registrypath)"
            }

            ##Creating the registry string and setting its value
            if ($RegistryPath -ne "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\")
                {
                         write-verbose "Setting the registry string $($RegistryString) with value $($registryvalue) at path : $($registrypath) ."

                        try{
                           
                            New-ItemProperty -Path $RegistryPath  -Name $RegistryString -PropertyType STRING -Value $RegistryValue -Force -ErrorAction Stop | Out-Null
                            }
                        catch [System.Security.SecurityException] {
                            log-message "No access to the registry. Please launch this function with elevated privileges."
                        }
                        catch{
                            log-message "An uncatched error occured : $_ "
                        }
                       }
            else{
                write-verbose "The registry path that is tried to be created is the uninstall string. HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\."
                write-verbose "Creating this here would have as consequence to erase the whole content of the Uninstall registry hive."
                exit
            }

               
            
            
        }

    End{}
}

Function Log-Message{
Param(
    [Parameter(Position=0)][string]$message,
    [Parameter(Position=1)]$LogFile = "C:\system\logs\osd\Manage-OSDTime.log"
    
)
    if(!(Test-Path $LogFile)){
        New-Item -ItemType file -Path $LogFile -Force | Out-Null
        write-host $message
        $message >> $LogFile
    }else{
        write-host $message
        $message >> $LogFile
    }
}

}
Process{
$ScriptVersion = "2.1"
    log-message "[OSDTIME]Starting Manage-OSDTime.ps1 with script version: $($Scriptversion)" 

    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment

    if ($start){
        
            $UTCNow = [System.DateTimeOffset]::UtcNow
            $tsenv.Value("StartTime") = $UTCNow.UtcDateTime 
            $tsenv.Value("StartTimeUTCTicks") = $UTCNow.UtcTicks
            log-message "[OSDTIME]Start time set to $($tsenv.Value('StartTime'))"

    }
    elseif($end){
            
            #getting existing startTime
                $StartTime = $tsenv.Value("StartTime")
                $StartTimeUTCTicks = $tsenv.Value("StartTimeUTCTicks")

                
                if (!($StartTime)){
                    Log-Message "[OSDTIME]Could not find the Task sequence variable 'StartTime'. Be sure that the variable has been set PRIOR this step using the -START switch"
                    $PSDistrict_OSDInstallTime = 'Undefined'
                }else{

                    log-message "[OSDTIME]Task sequence started at $($StartTime)."

                    #Getting end time
                        
                        
                        $PSDistrict_endTime = ([System.DateTimeOffset]::UtcNow).UtcDateTime
                        $EndTimeTicks = ([System.DateTimeOffset]::UtcNow).UtcTicks
                        $TimeSpan = new-object timespan(($EndTimeTicks - $StartTimeUTCTicks))
                        $PSDistrict_OSDInstallTime = [math]::Round($TimeSpan.TotalMinutes,2)

                        if (!($PSDistrict_OSDInstallTime)){
                            $PSDistrict_OSDInstallTime = 'Undefined'
                            log-message "[OSDTIME]Execution time could not be calculated. Please verify the Time settings of WinPE. Value is set to undefined."
                        }else{

                            if ($tattoo){
                                $FullRegPath = join-path -Path "HKLM:\SOFTWARE" -ChildPath $Root
                                New-RegistryItem -RegistryPath $FullRegPath -RegistryString "PSDistrict_OSDInstallationTime" -RegistryValue $PSDistrict_OSDInstallTime
                                log-message "[OSDTIME]Tattooed execution time value $($PSDistrict_OSDInstallTime) to registry (only). $($FullRegPath)"
                            }
                            else{
                                
                                $tsenv.Value("PSDistrict_OSDInstallTime") = $PSDistrict_OSDInstallTime 
                                log-message "[OSDTIME]Execution time is returned as a TS variable. Use New-OSDTattoo.ps1 to tattoo the information in the desired place."
                                log-Message "[OSDTIME]Installlation time --> $($PSDistrict_OSDInstallTime)"
                            }
                    
                        }
                    }
            
                

        }

}
end{
    log-message "[OSDTIME]End of Manage-OSDTIME.ps1 script. For more information check www.Powershelldistrict.com"
}
