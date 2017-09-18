#Math from here - http://datagenetics.com/blog/january12015/index.html
#Simple Deal or No Deal Game

<#
#To Do
Divide the cases into a left side and right side to provide commentary to the user if they made a good choice or bad choice
TTS as Howie Mandell?
Bankers offer and allow the user to accept the bankers offer and exit the game
#>

#Variables
#Simple Hashtable to instruct the program of how many cases to open each Round/Batch
$RoundRules = @{
    1 = 6
    2 = 5
    3 = 4
    4 = 3
    5 = 2
    6 = 1
    7 = 1
    8 = 1
    9 = 1
    10 = 1
}.GetEnumerator() | Sort-Object Name

#Brief Case values and randomize the order
$BriefcaseValues = @(
    .01
    1
    5
    10
    25
    50
    75
    100
    200
    300
    400
    500
    750
    1000
    5000
    10000
    25000
    50000
    75000
    100000
    200000
    300000
    400000
    500000
    750000
    1000000
) | Sort-Object {Get-Random} # Randomize the array so the user selects at Random

[System.Collections.ArrayList]$BriefcaseAmountsAll = @{} #Make a blank hashtable to assign the case values to

#Take the random values and assign them to their cases (hashtable)
for ($i = 0; $i -lt $BriefcaseValues.Count; $i++) {
    #Build a PS Custom Object for the Key Value Pair
    $BriefCase = New-Object -TypeName psobject
    $BriefCase | Add-Member -MemberType NoteProperty -Name 'Name' -Value ($i + 1)
    $BriefCase | Add-Member -MemberType NoteProperty -Name 'Value' -Value $BriefcaseValues[$i]
    
    Try {
        $BriefcaseAmountsAll.Add($BriefCase) | Out-Null
    } Catch {
        Write-Error 'Failed to add briefcase to hashtable'
    }
}

$BriefcaseAmountsAll = $BriefcaseAmountsAll.GetEnumerator() | Sort-Object Name
$BriefcaseAmountsAllOriginal = $BriefcaseAmountsAll.Clone()

#Functions
#Function to remove the user selected case from the Hashtable, this will always take the real work case number and find the corresponding entry
function Remove-CaseFromHashtable ($CaseNumber) {
    Write-Verbose "Removing case $CaseNumber from Hashtable"
    $BriefcaseAmountsAll.RemoveAt(($BriefcaseAmountsAll.Name.IndexOf($CaseNumber)))
}

Clear-Host

Write-Output 'Welcome to the text based version of Deal or no Deal staring you & PowerShell!'
Pause
Clear-Host
Write-Output 'Before we can continue, you need to select a briefcase to hold onto throughout the game'
Write-Output ('Remember you keep this till the end until you either keep or trade it, now select a case from {0:N0} to {1:N0}' -f ($BriefcaseAmountsAll.Value | Sort-Object)[0],($BriefcaseAmountsAll.Value | Sort-Object)[-1])

Write-Verbose "Listing all $($BriefcaseAmountsAll.Count) possible cases in the BriefcaseAmountsAll"
Write-Output 'Now select your case to keep!'
$UsersCaseSelection = $BriefcaseAmountsAll.GetEnumerator().Name |
    Sort-Object | 
    Select-Object @{Name='Case';Expression={$PSItem}} |
    Out-GridView -OutputMode Single -Title 'Select your personal case!'
    
#Remove the users selected case from the hashtable
Remove-CaseFromHashtable -CaseNumber $UsersCaseSelection.Case

Write-Output "You selected case $($UsersCaseSelection.Case), now lets hang onto that for you"
Pause

for ($Round = 1; $Round -le 10; $Round++) {
    Clear-Host #Clean the screen each loop 
    if (!($Round -eq 10)) {
        $CasesToOpen = $RoundRules[$Round - 1].Value
        Write-Output "Welcome to round $Round, before we continue you will have to open $CasesToOpen cases"

        for ($i = 0; $i -lt $CasesToOpen; $i++) {
            #Prompt the user to select a case
            $RoundSelectedCase = $BriefcaseAmountsAll.GetEnumerator().Name |
                Sort-Object | 
                Select-Object @{Name='Case';Expression={$PSItem}} |
                Out-GridView -OutputMode Single -Title 'Select your case!'

            #Tell the user the value of the case they just selected
            $CaseValue = $BriefcaseAmountsAll[($BriefcaseAmountsAll.Name.IndexOf($RoundSelectedCase.Case))].Value

            #If statement to change where the decimal place is
            if ($CaseValue -lt 1) {
                Write-Output ('You selected case {0} which had a value of ${1:N2}' -f $RoundSelectedCase.Case, $CaseValue)
            } else {
                Write-Output ('You selected case {0} which had a value of ${1:N0}' -f $RoundSelectedCase.Case, $CaseValue)
            }

            Remove-CaseFromHashtable -CaseNumber $RoundSelectedCase.Case #Remove the selected case so we don't see it anymore
        }

        #End of round, bankers offer
        Pause
    } else {
        Write-Output "Welcome to round $Round, this is different and we will allow you to switch cases if you choose"

        #Backup the original user selected case value
        $UsersCaseSelectionOriginal = $BriefcaseAmountsAllOriginal[($BriefcaseAmountsAllOriginal.Name.IndexOf($UsersCaseSelection.Case))]

        #Build a menu system for the user to select keep or swap their case
        $CaseSwapTitle = "Decision Time"
        $CaseSwapMessage = "Your case is $($UsersCaseSelection.Case) and you can swap with case $($BriefcaseAmountsAll.Key), would you like to switch cases?"
        
        $CaseKeep = New-Object System.Management.Automation.Host.ChoiceDescription "&Keep", 'Keep your case'
        $CaseSwap = New-Object System.Management.Automation.Host.ChoiceDescription "&Swap", 'Swap your case'
        
        $CaseSwapOptions = [System.Management.Automation.Host.ChoiceDescription[]]($CaseKeep, $CaseSwap)
        $result = $host.ui.PromptForChoice($CaseSwapTitle, $CaseSwapMessage, $CaseSwapOptions, 0) 
        
        switch ($result) {
            0 {
                Write-Output 'You selected to keep your case'
            }
            1 {
                Write-Output 'You selected to swap your case'
                $UsersCaseSelection = $BriefcaseAmountsAll[0].Name #Swap the case
            }
        }

        Clear-Host
        Write-Output 'Ready to see the result?'
        Pause

        #Find the value of the users current case
        $CaseValue = $BriefcaseAmountsAllOriginal[($BriefcaseAmountsAllOriginal.Name.IndexOf($UsersCaseSelection.Case))].Value

        #If statement to change where the decimal place is
        if ($CaseValue -lt 1)  {
            $WinningValue = '{0:N2}' -f $CaseValue
        } else {
            $WinningValue = '{0:N0}' -f $CaseValue
        }

        #See if the user made a good or bad swap
        if ($CaseValue -lt $UsersCaseSelectionOriginal.Value) {
            Write-Output('Sorry but your original case was worth ${0}, you did win ${1} though!' -f $UsersCaseSelectionOriginal.Value,$WinningValue)
        } else {
            Write-Output "You won big with a grand total of $WinningValue!"
        }
    }
}

