Param (
    [Parameter(Mandatory=$True,Position=1)]
     [string]$InputFile
)
<#
Need to detect whether a set of source/target CIFS servers
used 3DNS aliasing or LB aliasing

#### LB Aliasing

- LB Aliasing changes the IP address of the old name to the target VDM IP
- Old computer object in AD gets deleted
- LB Aliasing will return old vfiler name in forward lookup of source vFiler
    - In reverse lookup, it will return the Target VDM name

#### 3DNS Aliasing

- 3DNS adds old name as an alias on target VDM
- Old computer object in AD gets deleted
- 3DNS Aliasing will return new VDM name in forward lookup of source vFiler, old vFiler name as alias
    - In reverse lookup, it will return VDM as name


#>

BEGIN {

    $DATA = Import-Csv -Path $InputFile


}

PROCESS {

    ForEach ($R in $DATA) {

        # Forward Lookup of Source vFiler
        # Forward Lookup of Target VDM
        # Ping of source vFiler
        # Ping of target VDM

        # If forward lookup of source returns source name
            # Then migration was done with LB
        # ElseIf forward lookup of source returns target name
            # Then migration was done with 3DNS

    }

}

END {

}


