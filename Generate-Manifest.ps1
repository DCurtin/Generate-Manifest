function addElementsToManifest($name, $member, $manifest)
{

    #echo "$name, $member, $manifest"
    
    if($manifest -eq $null)
    {
        return
    }


    $types_element = $manifest.CreateElement('types', "http://soap.sforce.com/2006/04/metadata")

    $types_members_element = $manifest.CreateElement('members', 'http://soap.sforce.com/2006/04/metadata')
    $types_members_element.InnerText=$member > $null
    $types_element.AppendChild($types_members_element)
    
    $types_name_element = $manifest.CreateElement('name', 'http://soap.sforce.com/2006/04/metadata')
    $types_name_element.InnerText=$name > $null
    $types_element.AppendChild($types_name_element)
    
    $manifest.Package.AppendChild($types_element)
}
function Generate-Manifest
{
    param(
    [string]$regexClass='',
    [string]$regexTrigger='',
    [string]$path='.'
    )

    New-Item -Path "$path\+package.xml" -Force > $null

    if($regexClass -eq '' -and $regexTrigger -eq '')
    {
        echo 'Please provide at least one argument: Generate-Manfiest -regexClass "\w*test$" or Generate-Manfiest -regexTrigger "\w*triggerendswiththis$"' 
        return
    }
    echo 'querying class names'

    [System.Collections.ArrayList] $classNames = sfdx force:data:soql:query -q "SELECT Name FROM ApexClass" -r csv -u 'dcurtin@midlandira.com'
    $classNames.RemoveAt(0)
    [System.Collections.ArrayList] $triggerNames = sfdx force:data:soql:query -q "SELECT Name FROM ApexTrigger" -r csv -u 'dcurtin@midlandira.com'
    $triggerNames.RemoveAt(0)
    
    [XML]$BLANK_MAN='<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Package xmlns="http://soap.sforce.com/2006/04/metadata">
        <version>45.0</version>
    </Package>'
    
    echo 'Starting Package Creation'

    if($regexClass -eq '')
    {
        $classNames.ForEach(
            {
                if($_ -match $regexClass)
                { 
                    #echo "ApexClass, $_, $BLANK_MAN"
                    addElementsToManifest 'ApexClass' $_ $BLANK_MAN
                }
            }
        )
    }

    if($regexTrigger -eq '')
    {
        $triggerNames.ForEach(
            {
                if($_ -match $regexTrigger)
                {
                    #echo "ApexTrigger, $_, $BLANK_MAN"
                    addElementsToManifest 'ApexTrigger' $_ $BLANK_MAN
                }
            }
        )
    }
    
    echo 'generating package.xml'
    $BLANK_MAN.save("$path\package.xml")
}
#Export-ModuleMember -Function Generate-Manifest