Write-Host "This script can compare two file structures in three different ways:  tree, file, and hash. `
The tree comparison will compare the source and destination trees based on file name, attributes, and size (length) `
The hash comparison will compute a hash of each source and destination file and compare them (data integrity check) `
The file comparison will compare files only and not directories.  This is requried to compare Last Modified Dates (directories are always different) `
**The hash comparison can take some time, depending on the amount of data**"

# Prompt user for required information.
$COMPTYPE = Read-Host "What kind of comparison do you want to perform [ tree | file | hash ] "
$SRCTREE = Read-Host "Enter the source folder (\\computer\share or C:\dir) "
$DSTTREE = Read-Host "Enter the destination folder (\\computer\share or C:\dir) "
$SHARE = Read-Host "Enter the name of the share (for log file) "

switch ($COMPTYPE) 
    {  
        tree {
              Write-Host "Gathering Data"
              $SRCFILES = Get-ChildItem -Recurse -LiteralPath $SRCTREE
              $DSTFILES = Get-ChildItem -Recurse -LiteralPath $DSTTREE
              Write-Host "Comparing Trees"
              $TREECOMPARE = Compare-Object -ReferenceObject $SRCFILES -DifferenceObject $DSTFILES -Property Name,Length,Attributes -PassThru -IncludeEqual -SyncWindow 1000000 `
                | Select-Object @{n="Full Path"; e={($_ | select -expandproperty FullName) -join ','}},SideIndicator,Length,Attributes
              Write-Host "Creating Report"
              $OUTFILEDATE = Get-Date -Format "yyyyMMddhhmmss"
              $OUTFILELOC = Get-Location
              $TREECOMPARE | ConvertTo-Html -Title "Tree Comparison of $SRCTREE and $DSTTREE" `
                            | Out-File .\"$OUTFILEDATE"_$SHARE-tree-comparison.html
              Write-Host -NoNewLine "Report saved to"$OUTFILEDATE"_$SHARE-tree-comparison.html in current directory"
        }
        
        hash {
              Write-Host "Gathering Data"   
              $SRCFILES = Get-ChildItem -Recurse -LiteralPath $SRCTREE
              $DSTFILES = Get-ChildItem -Recurse -LiteralPath $DSTTREE
              Write-Host "Computing Hashes"
              $SRCHASH = $SRCFILES | Get-FileHash
              $DSTHASH = $DSTFILES | Get-FileHash
              Write-Host "Comparing File Hashes"
              $HASHCOMPARE = Compare-Object -ReferenceObject $SRCHASH -DifferenceObject $DSTHASH -Property Hash -PassThru -IncludeEqual -SyncWindow 1000000 `
                    | Select-Object Path,SideIndicator,Hash
              Write-Host "Creating Report"
              $OUTFILEDATE = Get-Date -Format "yyyyMMddhhmmss"
              $OUTFILELOC = Get-Location
              $HASHCOMPARE | ConvertTo-Html -Title "Hash Comparison of $SRCTREE and $DSTTREE" `
                            | Out-File .\"$OUTFILEDATE"_$SHARE-hash-comparison.html
              Write-Host -NoNewLine "Report saved to"$OUTFILEDATE"_$SHARE-tree-comparison.html in current directory"
        }

        file {
              Write-Host "Gathering Data"
              $SRCFILES = Get-ChildItem -Recurse -LiteralPath $SRCTREE | Where-Object {$_.Attributes -eq "Archive"}
              $DSTFILES = Get-ChildItem -Recurse -LiteralPath $DSTTREE | Where-Object {$_.Attributes -eq "Archive"}
              Write-Host "Comparing Files"
              $FILECOMPARE = Compare-Object -ReferenceObject $SRCFILES -DifferenceObject $DSTFILES -Property Name,Length,Attributes,LastWriteTime -PassThru -IncludeEqual -SyncWindow 1000000 `
                | Select-Object @{n="Full Path"; e={($_ | select -expandproperty FullName) -join ','}},SideIndicator,Length,LastWriteTime,Attributes
              Write-Host "Creating Report"
              $OUTFILEDATE = Get-Date -Format "yyyyMMddhhmmss"
              $OUTFILELOC = Get-Location
              $FILECOMPARE | ConvertTo-Html -Title "File Comparison of $SRCTREE and $DSTTREE" `
                            | Out-File .\"$OUTFILEDATE"_$SHARE-file-comparison.html
              Write-Host -NoNewLine "Report saved to"$OUTFILEDATE"_$SHARE-file-comparison.html in current directory"
        }
    }