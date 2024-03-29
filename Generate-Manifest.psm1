﻿function addElementsToManifest
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
    [string]$regexPage='',
    [string]$path=$(pwd),
    [string]$targetusername
    )

    if($targetusername -eq '' -or $targetusername -eq $null)
    {
        echo "Please provide a username or org alias name for -targetusername
        e.g. dcurtin@midlandira.com [assuming this is the username used to authenticate to an org]
             DevHub                 [assuming this is a defined alias for an org]
             Use sfdx force:org:list to get a list of org aliases"
        return
    }

    if($regexClass -eq '' -and $regexTrigger -eq '' -and $regexPage -eq '')
    {
        echo "`nPlease provide at least one argument
        e.g. Generate-Manifest -regexClass '^Trail\w*test$'`t [begins with Trail ends with test]
             Generate-Manifest -regexTrigger 'testString$'`t [begins with anything, ends with testString]
             Generate-Manifest -regexClass 'test,merge'`t`t [any class with test or merge in it's name]
             Generate-Manifest -regexPage 'test,merge'`t`t [any page with test or merge in it's name]"
        return
    }

    New-Item -Path "$path\package.xml" -Force > $null
    $resolvedPath = Resolve-Path "$path\package.xml"

    [System.Collections.ArrayList] $regexClassList = $regexClass.Split(',')
    [System.Collections.ArrayList] $regexTriggerList = $regexTrigger.Split(',')
    [System.Collections.ArrayList] $regexPageList = $regexPage.Split(',')

    echo 'querying names'

    [System.Collections.ArrayList] $classNames = sfdx force:data:soql:query -q "SELECT Name FROM ApexClass" -r csv -u $targetusername
    $classNames.RemoveAt(0)#remove header
    [System.Collections.ArrayList] $triggerNames = sfdx force:data:soql:query -q "SELECT Name FROM ApexTrigger" -r csv -u $targetusername
    $triggerNames.RemoveAt(0)#remove header
    [System.Collections.ArrayList] $pageNames = sfdx force:data:soql:query -q "SELECT Name FROM ApexPage" -r csv -u $targetusername
    $pageNames.RemoveAt(0)#remove header
    
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

    if($regexPageList[0] -ne '')
    {
        foreach($page in $pageNames)
        {
            foreach($regex in $regexPageList)
            {
                if($page -match $regex)
                { 
                    #echo "ApexClass, $_, $BLANK_MAN"
                    addElementsToManifest 'ApexPage' $page $BLANK_MAN
                }
            }
        }
    }
    
    echo 'generating package.xml'
    $BLANK_MAN.save($resolvedPath)
}
    Export-ModuleMember -Function Generate-Manifest