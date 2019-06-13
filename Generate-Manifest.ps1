function addElementsToManifest
{
    param(
    [string]$name='',
    [string]$member='',
    [XML]$manifest=$null
    )
    
    if($manifest -eq $null)
    {
        return
    }

    $types_element = $manifest.CreateElement('types', "http://soap.sforce.com/2006/04/metadata")

    $types_members_element = $manifest.CreateElement('members', 'http://soap.sforce.com/2006/04/metadata')
    $types_members_element.InnerText=$member
    $types_element.AppendChild($types_members_element)
    
    $types_name_element = $manifest.CreateElement('name', 'http://soap.sforce.com/2006/04/metadata')
    $types_name_element.InnerText=$name
    $types_element.AppendChild($types_name_element)
    
    $manifest.Package.AppendChild($types_element)

    return $manifest
}
function Generate-Manifest
{
    param(
    [string]$regexClass='',
    [string]$regexTrigger='',
    [string]$path=$(pwd)
    )

    if($regexClass -eq '' -and $regexTrigger -eq '')
    {
        echo "`nPlease provide at least one argument `n`n e.g.`tGenerate-Manifest -regexClass '^Trail\w*test$'`t [begins with Trail ends with test]
        Generate-Manifest -regexTrigger 'testString$'`t [begins with anything, ends with testString]
        Generate-Manifest -regexClass 'test,merge'`t`t [any class with test or merge in it's name]"
        return
    }

    New-Item -Path "$path\package.xml" -Force > $null

    [System.Collections.ArrayList] $regexClassList = $regexClass.Split(',')
    [System.Collections.ArrayList] $regexTriggerList = $regexTrigger.Split(',')


    echo 'querying class names'

    [System.Collections.ArrayList] $classNames = sfdx force:data:soql:query -q "SELECT Name FROM ApexClass" -r csv -u 'dcurtin@midlandira.com'
    $classNames.RemoveAt(0)#remove header
    [System.Collections.ArrayList] $triggerNames = sfdx force:data:soql:query -q "SELECT Name FROM ApexTrigger" -r csv -u 'dcurtin@midlandira.com'
    $triggerNames.RemoveAt(0)#remove header
    
    [XML]$BLANK_MAN='<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Package xmlns="http://soap.sforce.com/2006/04/metadata">
        <version>45.0</version>
    </Package>'
    
    echo 'Starting Package Creation'

    if($regexClassList[0] -ne '')
    {
        foreach($class in $classNames)
        {
            foreach($regex in $regexClassList)
            {
                if($class -match $regex)
                { 
                    #echo "ApexClass, $_, $BLANK_MAN"
                    addElementsToManifest 'ApexClass' $class $BLANK_MAN
                }
            }
        }
    }

    if($regexTriggerList[0] -ne '')
    {
        foreach($trigger in $triggerNames)
        {
            foreach($regex in $regexTriggerList)
            {
                if($trigger -match $regex)
                { 
                    #echo "ApexClass, $_, $BLANK_MAN"
                    addElementsToManifest 'ApexTrigger' $trigger $BLANK_MAN
                }
            }
        }
    }
    
    echo 'generating package.xml'
    $BLANK_MAN.save("$path\package.xml")
}
#Export-ModuleMember -Function Generate-Manifest