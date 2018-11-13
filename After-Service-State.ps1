$hosts = $env:computername

write-host "Computer name is $hosts"

$Folderpath = $env:TEMP

$postReboot = get-Service * | where {$_.Status -eq "Running"}

$postReboot |  Export-Clixml -Path $Folderpath\postreboot-service.xml

 if ((Test-Path "$Folderpath\preboot-service.xml") -and (Test-Path "$Folderpath\postreboot-service.xml")) {

      [PsObject]$xmlBefore = Import-Clixml -Path "$Folderpath\preboot-service.xml"
        [PsObject]$xmlAfter = Import-Clixml -Path "$Folderpath\postreboot-service.xml"

        $CompareBefore = @()
        $CompareAfter = @()

        $CompareBefore = Compare-Object $xmlBefore $xmlAfter -Property SystemName,Name,DisplayName,State,StartMode | where {$_.SideIndicator -EQ "<="}
        $CompareAfter = Compare-Object $xmlBefore $xmlAfter -Property SystemName,Name,DisplayName,State,StartMode | where {$_.SideIndicator -EQ "=>"} 
        if ((!$CompareBefore) -and (!$CompareAfter)) 
		{
		Write-Host " No differences in Service State After Reboot on $hosts " 
		Break
		}
	
		

        $obj = @()
        $obj += ForEach ($line1 in $xmlBefore) {  # Looking for all rows in the first CSV file
	                ForEach ($line2 in $xmlAfter) {  # Looking for all rows in the second CSV file
			            if ($line1.name -eq $line2.name) {  # If the same service name is found in both files
				            if (($line1.startmode -ne $line2.startmode) -or ($line1.state -ne $line2.state)) {  # If different
								
							    New-Object -TypeName PSObject -Property @{
                                    SystemName = $line1.SystemName
                                    Rebooted_Hrs = $RebootDiffHours
								    Name = $line1.name
                                    DisplayName =  $line1.DisplayName   
								    StartMode_Before = $line1.startmode
								    StartMode_After = $line2.startmode 
                                    State_Before = $line1.state
								    State_After = $line2.state
							        }  
				            }
				        }
		            }
                }

    foreach ($line1b in $CompareBefore) {
        $found = $false
            foreach ($line1a in $CompareAfter) {
                If ($line1a.DisplayName -eq $line1b.DisplayName) {
                    $found = $true
                    }
            }
            if ($found -eq $false) {
                $obj += New-Object -TypeName PSObject -Property @{
                    SystemName = $line1b.SystemName
                    Rebooted_Hrs = $RebootDiffHours
					Name = $line1b.name
                    DisplayName =  $line1b.DisplayName   
					StartMode_Before = $line1b.startmode 
					State_Before = $line1b.state
					StartMode_After = '---'
                    State_After = '---'
				}  
            }
        }

    $Final += $Obj

    } # End of If Test-path

    $Final2 = @()
    $Final2 = $Final | sort DisplayName | Select Name,DisplayName
	Write-Host  "Only Displaying Services State Which Changed after Server Reboot `n"
	$Final2 | Format-Table

#Start-Sleep -s 60

#$remove = Remove-Item -Path $Folderpath\preboot-service.xml -Force
#$remove = Remove-Item -Path $Folderpath\postreboot-service.xml -Force
