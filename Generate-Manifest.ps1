function addElementsToManifest($name, $member, $manifest)
{
    $types_element = $manifest.CreateElement('types', "http://soap.sforce.com/2006/04/metadata")
    
    $types_members_element = $manifest.CreateElement('members', 'http://soap.sforce.com/2006/04/metadata')
    $types_members_element.InnerText=$member
    $types_element.AppendChild($types_members_element)
    
    $types_name_element = $manifest.CreateElement('name', 'http://soap.sforce.com/2006/04/metadata')
    $types_name_element.InnerText=$name
    $types_element.AppendChild($types_name_element)
    
    $manifest.Package.AppendChild($types_element)
}
function Generate-Manifest
{
    param(
    [string]$regexClass=$null,
    [string]$regexTrigger=$null
    )


    if($regexClass -eq $null -and $regexTrigger -eq $null)
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

    if($regexClass -ne $null)
    {
        $classNames.ForEach(
            {
                if($_ -match $regexClass)
                {
                    addElementsToManifest('ApexClass', $_, $BLANK_MAN)
                }
            }
        )
    }

    if($regexTrigger -ne $null)
    {
        $triggerNames.ForEach(
            {
                if($_ -match $regexTrigger)
                {
                    addElementsToManifest('ApexTrigger', $_, $BLANK_MAN)
                }
            }
        )
    }
    
    echo 'generating package.xml'
    $BLANK_MAN.save('C:\users\dcurtin\package.xml')
}
#Export-ModuleMember -Function Generate-Manifest