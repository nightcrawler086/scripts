# See if I can use powershell to process the data in the tracker
# without having to save it as a CSV
#

BEGIN {

    $TRPATH = "" # Path to tracker

    If ( ! Test-Path $TRPATH ) {
        Write-Output "Could not find the tracker at this path:  $TRPATH"
        Exit
    }

    $TRSHEET = "Global NAS Tracker"
    # New Excel COM Object
    $EXCEL = New-Object -ComObject Excel.Application
    $EXCEL.Visible = $False
    $TR = $EXCEL.WorkBooks.Open($TRPATH)
    $SHEET = $TR.Sheets.Item($TRSHEET)

    $SLICE = # Slice the file ere based on the current week


}

PROCESS {

    ForEach ($R in $SLICE) {
        # Date should be good already
        # Validate that thare is a CHG number in the correct field
        # Check for Tech Contact
        # Make a copy of the NAS Migration Checklist
            # Test if it exists
        # Populate it with the volume / contact / CHG info
    }

}

END {

    # console report

}

