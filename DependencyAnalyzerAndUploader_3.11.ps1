
#31/08/2017 - Added menu option "4" for lib folder and  option "6" for gradle file creation
echo "`n"
echo **********************************
echo " Transitive Dependency Analyzer "
echo **********************************
echo "`n"
$ErrorActionPreference="stop"
$Script:outputDir = $null
$Script:local_repo_list=$null
$Script:local_repo=$null
$Script:found = $null
$Script:app_id = ""
$Script:buildFilePath = ""
$Script:DependencyReportPath = ""
$Script:outputDir = ""
$Script:artifact_list = ""
$Script:jarArray= @()
#$Script:yes_regex = 'y|Y'
$Script:yes_regex = '^[Y]$'
$Script:no_regex = '^[N]$'
$Script:yes_no_regex = '^[YN]$'
$Script:option_regex = '^([0-2])$'
$Script:valid_MainMenu = '1|2|3|4'
$Script:valid_1_buildFileMenu = '^([1-3])$'
$Script:etp_art_url = "http://artifactory.wellsfargo.com/artifactory"
$Script:foss_art_url = "http://cpvra00a0223.wellsfargo.com:8090/artifactory"
$Script:main_menu_regex = '^([1-4])$'
$Script:1_menu_regex = '^([0-5])$'

$Script:3_menu_regex = '^([0-2])$'
$Script:4_menu_regex = '^([0-3])$'
$Script:1_5_menu_regex = '^([0-2])$'
$Script:xyz_regex = '^[YN]$'
$Script:is_search_lob = ""
#For dependecy uploader
$Script:pathArray = @()
$Script:dependencyJarPath = ""
$Script:aqlMid = ""
$Script:searchRepos = ""
#Menu options
$Script:main_option = ""
$Script:1_option = ""
$Script:3_option = ""
$Script:4_option = ""
$Script:1_5_option = ""
$Script:data = @()
$Script:data1 = @()
$Script:unavail_dll = @()
$Script:avail_dll = @()
$Script:notFound = @()
$Script:un_etp = @()
$Script:un_foss = @()
$Script:myarr = @()
$Script:unavail = @()
$Script:allInfoArr = @()
$Script:altArr = @()
$Script:notFoundAtr = @()
$Script:sno = 0

#For gradle file option to add multiple occurances of an artifact 
$Script:obtainedJarsArray = @() 
#Method to check if JAVA_HOME is set
function checkJavaHome {
    if (Test-Path $env:JAVA_HOME) {
        if (!($env:Path.Contains($env:JAVA_HOME))) {
            $env:Path = "$env:JAVA_HOME\bin"
        }
    }else{
        if (Test-Path "C:\Program Files\Java") {
            $java=gci -Path 'C:\Program Files\Java' -Recurse -Include "jar.exe" -File
            $env:Path=$java[0].FullName.Replace("\jar.exe","")
        }else{ 
            echo "`n"
            echo "JAVA_HOME is not set and Cannot find Java installtion in `"C:\Program Files (x86)`". Please ensure JAVA_HOME is set in PATH."
            }        
    }
}


#Method to display main menu
function main_menu {
    echo "Select Operation"
    echo "`n"
    echo "Enter 1 for Search and Analysis for Dependencies"
    echo "Enter 2 for Dependency Upload from Excel File"
    echo "Enter 3 for Transitive dependency tree"
    echo "Enter 4 to Exit"
    echo "`n"
    $Script:main_option=read-host "Select"
    while ($Script:main_option.Trim() -eq "") 
    {
        echo "Selection cannot be empty"
        $Script:main_option=read-host "Select"
    }
    while (!($Script:main_option -match $Script:main_menu_regex)){ 
        echo "Invalid selection. Please select from the given options`n" 
        main_menu 
       # $Script:main_option=read-host "Select" 
    } 

  if ($Script:main_option -eq 1) {
    1_menu
    }
    if ($Script:main_option -eq 3) {
    4_menu
    }
}
function 1_menu {
    echo "`n"
    echo "Select input type"
    echo "Enter 1 for Maven Build File"
    echo "Enter 2 for Gradle Build File"
    echo "Enter 3 for Ant Build File"
    echo "Enter 4 for Nuget Repo"
    echo "Enter 5 for Local Repo"
    echo "Enter 0 for previous menu"
    echo "`n"
    $Script:1_option=read-host "Select"
    while ($Script:1_option.Trim() -eq "") 
    {
        echo "Selection cannot be empty"
        $Script:1_option=read-host "Select"
    }
    while(!($Script:1_option -match $Script:1_menu_regex)){
        echo "Invalid selection. Please select from the given options`n"
        $Script:1_option=read-host "Select"
    }

if ($Script:1_option -eq 5) {
    1_5_menu
    }
    if ($Script:1_option -eq 0) {
    main_menu
    }
}
function 1_5_menu {
    echo "`n"
    echo "Select input type"
    echo "Enter 1 for Maven"
    echo "Enter 2 for Non-Maven Repo"
    echo "Enter 0 for previous menu"
    echo "`n"
    $Script:1_5_option=read-host "Select"
    while ($Script:1_5_option.Trim() -eq "")
    {
        echo "Selection cannot be empty"
        $Script:1_5_option=read-host "Select"
    }
    while(!($Script:1_5_option -match $Script:1_5_menu_regex)){
        echo "Invalid selection. Please select from the given options`n"
        $Script:1_5_option=read-host "Select"
    }
    
    if ($Script:1_5_option -eq 0) {
    1_menu
    }
}


function 4_menu {
    echo "`n"
    echo "Enter 1 for GAV values"
    echo "Enter 2 for POM XML"
    echo "Enter 3 for IVY XML"
    echo "Enter 0 for previous menu"
    echo "`n"
    $Script:4_option=read-host "Select"
    while ($Script:4_option.Trim() -eq "") 
    {
        echo "Selection cannot be empty"
        $Script:4_option=read-host "Select"
    }
    while(!($Script:4_option -match $Script:4_menu_regex)){
        echo "Invalid selection. Please select from the given options`n"
        $Script:4_option=read-host "Select"
    }
    
     if ($Script:4_option -eq 0) {
      main_menu
    }
}

function accessCheck($url) {
    $Script:flag = 1
    try{
        $output = Invoke-WebRequest -Uri $url
    }
    catch{
        write-host "The url: $url you are trying to access is down right now. We will try to re-access it after 5 seconds."
        Start-Sleep -s 5 
        
        try{
            $output = Invoke-WebRequest -Uri $url
        }
        catch {
            write-host "The url: $url you are trying to access is down right now. Please try after sometime."
            $Script:flag = 0
            echo ""
            echo "Skipping search in $url as it is currently down"
            echo ""
        } 
    }
}

#Method to get virtual repo names as user input
function getRepoNames {
    $Script:searchRepos=read-host "Enter name of all Enterprise artifactory virtual repos to be searched (comma seperated)"
    $hdrEnt = @{ "X-JFrog-Art-Api" = "$global:apikey_etp" }
    while ($Script:searchRepos.Trim() -eq "" -or $Script:aqlMid -eq "") 
    {
        if($Script:searchRepos.Trim() -eq ""){
        echo "Repo name cannot be empty. Please enter a valid input"
        $Script:searchRepos=read-host "Enter name of all Enterprise artifactory virtual repos to be searched (comma seperated)"
        }
        $repoNames = $Script:searchRepos.Split(",")
    
    for($i = 0; $i -lt $repoNames.Count; $i++) {
        $repoName = $repoNames[$i].Trim()
        $temp = '"repo": "' + $repoName + '",'
        
        try{
        
        $repo_result=Invoke-RestMethod -Method GET -Uri "$Script:etp_art_url/api/storage/$repoName" -Headers $hdrEnt
            
            if(!($repo_result

.children.Count -eq 0)){
                $Script:aqlMid = $Script:aqlMid + $temp
            }
        }
            catch [Exception]{}
    }
        if($Script:aqlMid -eq ""){
                echo "User does not have access to any of the repos entered. Please enter repos with appropriate access`n"
                $Script:searchRepos=read-host "Enter name of all Enterprise artifactory virtual repos to be searched (comma seperated)"
        }
    }
}

# Function for user authentication for Enterprise repo 
function apikey_etp { 
echo "`n" 
    echo "User authentication. Please enter your details as prompted" 
    echo "`n" 
    $global:apikey_etp=read-host "Enter apiKey for Enterprise Artifactory - http://artifactory.wellsfargo.com/artifactory/"
    $Script:auth = $null 
    $hdr = @{ "X-JFrog-Art-Api" = "$global:apikey_etp" } 
    while ($apikey_etp -eq "" -or $Script:auth.Count -eq 0) { 
        try{ $Script:auth=Invoke-RestMethod -Method GET -Uri "http://artifactory.wellsfargo.com/artifactory/api/security/encryptedPassword" -Headers $hdr }
        catch [Exception] {} 

if($apikey_etp -eq ""){ 
            echo "API Key cannot be empty. Please enter a valid input`n" 
            $global:apikey_etp = $null 
        } 
        elseif ($Script:auth.Count -eq 0) { 
            echo "Unauthorized access to Artifactory. Please enter the API key with appropriate access`n" 
            $global:apikey_etp = $null 
            $Script:auth = $null 
            } 
        if ($global:apikey_etp -eq $null){ 
        $global:apikey_etp=read-host "Enter apiKey for Enterprise Artifactory - http://artifactory.wellsfargo.com/artifactory/"
        $hdr = @{ "X-JFrog-Art-Api" = "$global:apikey_etp" } 
        } 
    } 
} 


# Function for user authentication for FOSS repo 
function apikey_foss { 
    echo "`n" 
    $global:apikey_foss=read-host "Enter apiKey for FOSS Prod Artifactory - http://cpvra00a0223.wellsfargo.com:8090/artifactory/"  
    $Script:auth = $null 
    $hdr = @{ "X-JFrog-Art-Api" = "$global:apikey_foss" } 
    while ($apikey_foss -eq "" -or $Script:auth.Count -eq 0) { 
        try{ $Script:auth=Invoke-RestMethod -Method GET -Uri "http://cpvra00a0223.wellsfargo.com:8090/artifactory/api/security/encryptedPassword" -Headers $hdr }
        catch [Exception] {} 
        if($apikey_foss -eq ""){ 
            echo "API Key cannot be empty. Please enter a valid input`n" 
            $global:apikey_foss = $null 
        } 
        elseif ($Script:auth.Count -eq 0) { 
            echo "Unauthorized access to Artifactory. Please enter the API key with appropriate access`n" 
            $global:apikey_foss = $null 
            $Script:auth = $null 
            } 

     if ($global:apikey_foss -eq $null){ 
        $global:apikey_foss=read-host "Enter apiKey for FOSS Prod Artifactory - http://cpvra00a0223.wellsfargo.com:8090/artifactory/"
        $hdr = @{ "X-JFrog-Art-Api" = "$global:apikey_foss" } 
        } 
    } 
}
 
#Method to retain user creds
function usePreviousCreds {
   
    #if (Test-Path Variable:apikey_etp) {
    if (((Test-Path Variable:apikey_etp) -and (Test-Path Variable:apikey_foss)) -and (!($global:apikey_etp -eq $null) -and !($global:apikey_foss -eq $null))){
        echo "`n"
        echo "Use credentials entered before?"
        $Script:cred_choice=read-host "Enter Y/N"
        #while (!($Script:cred_choice -eq "Y" -or $Script:cred_choice -eq "y" -or $Script:cred_choice -eq "N" -or $Script:cred_choice -eq "n" ))
        while($Script:cred_choice -notmatch $Script:yes_no_regex)
    {
        echo "Invalid selection. Please select from Y/N`n"
        $Script:cred_choice=read-host "Enter Y/N"
    }

if ($Script:cred_choice -eq "Y" -or $Script:cred_choice -eq "y"){
    echo "Using previous credentials"
    } else {
            if(($Script:main_option -eq 2) -or ($Script:main_option -eq 2)){
                apikey_etp
            }
            else{
                apikey_etp
                apikey_foss
            }
        }
} else {
        if(($Script:main_option -eq 2) -or ($Script:main_option -eq 3)){
            apikey_etp
        }
    
        else{
            apikey_etp
            apikey_foss
        }
    }
} 


function validateLocalRepo{
    while (($Script:local_repo -eq "") -or !(Test-Path $Script:local_repo) -or ($Script:found -eq $null)) {
        
        if ($Script:local_repo -eq ""){ 
            echo "Repository location cannot be empty. Please provide a valid location`n" 
            $Script:local_repo = $null
        }
        
        elseif(!(Test-Path $Script:local_repo)){ 
            echo "Path does not exist. Please enter a valid Repository path`n" 
            $Script:local_repo = $null
        }
        elseif($Script:found -eq $null){
            # Check as per the option selected. If option is 3 then all the dlls and Nupkg names will be collected under the found array.
            # Else all the jar file names will be collected in found array.
            if ($1_option -eq 4) {
                $Script:found = @()


 try{
                $Script:nupkg = get-childitem $Script:local_repo  -Recurse -Include ('*.nupkg')
                $Script:dll = get-childitem $Script:local_repo  -Recurse -Include ('*.dll')
                
                foreach($check in $Script:dll){
                    $flag=0
                   for($i=0; $i -lt $nupkg.Count; $i++) {
                    $name=$nupkg[$i].FullName.ToLower().replace(".nupkg","")+"\lib" 
                        if ($check.FullName.ToLower().contains("$name")){ 
                            $flag=1
                        }
                    }
                    if ($flag -eq 0){$Script:found+=$check
                    }
                }
                
                $Script:found += $Script:nupkg
                # Validating the data found from the user repo location. If relevant data is found user will be asked to enter repo with relevant data
                

if($Script:found.Count -eq 0) { 
                    echo "No nupkg's or dll's found from the specified input location.Please provide an input folder .NET build dependencies`n"
                    $Script:local_repo = $null
                    $Script:found = $null
                    }
                }
                catch [Exception]{
                    echo "User does not have read access to one or more folders/sub-folders in this path. Please provide an input folder with read access`n"
                    $Script:local_repo = $null
                    $Script:found = $null
                }
            }else {
                try{$Script:found = gci -Path $Script:local_repo -Recurse -Include "*.jar" -File
                    if($Script:found -eq $null) { 
                        echo "No JAR files found from the specified input location. Please provide an input folder with JAR files`n" 
                        $Script:local_repo = $null
                        

catch [Exception]{
                echo "User does not have read access to one or more folders/sub-folders in this path. Please provide an input folder with read access`n"
                $Script:local_repo = $null
                }
            }
        }
        if ($Script:local_repo -eq $null){
            if ($Script:1_5_option -eq "1") {$Script:local_repo=read-host "Enter Maven Local repository location"}
            if ($Script:1_5_option -eq "2") {$Script:local_repo=read-host "Enter JAR files location"}
            if ($Script:1_option -eq "4"){$Script:local_repo=read-host "Enter user workspace location"}
            if($Script:3_option -eq 2){return}
        }
    }
}

function searchType {
        echo "`n"
        echo "Select search type"
        echo "Enter 1 to Search entire Enterprise Artifactory"
        echo "Enter 2 for Search in specific repo of Enterprise Artifactory"
        $Script:search_type=read-host "Select"
    
        while ($Script:search_type.Trim() -eq "" -or !($Script:search_type -match $Script:option_regex)) 
         {
            if($Script:search_type.Trim() -eq ""){
                echo "Choice cannot be empty. Please enter a valid input"
                $Script:search_type=read-host "Select"
            }
            else {
                echo "Choice should be either 1 or 2. Please enter a valid input"
                $Script:search_type=read-host "Select"
            }
        }

 if ($Script:search_type -eq 2) {
            getRepoNames
        } else {
            echo "`n"
            echo "Search in entire Enterprise Artifactory"
            }
}
function getInputs {
    $Script:app_id=read-host "Enter Application ID (less than or equal to 14 characters)"
    while ($Script:app_id.Trim() -eq "") 
    {
        echo "Application ID cannot be empty. Please enter a valid input"
        $Script:app_id=read-host "Enter Application ID (less than or equal to 14 characters)"
    }
    $Script:app_id=$Script:app_id.Trim()
    while ($Script:app_id.Length -gt 14){
    echo "The application ID should be less than or equal to 14 characters."
    $Script:app_id=read-host "Enter Application ID (less than or equal to 14 characters)"
    }
    echo "Removing special characters from the application ID if any." 
    $Script:app_id=$Script:app_id -replace '[\W]', ''   
    echo "The application ID is: $Script:app_id "

if($4_option -eq 3){
        echo "`n"
        $Script:uid=read-host "Enter your UID"
        while($Script:uid -eq ""){
        echo "UID cannot be null. Please enter a valid input"
        $Script:uid=read-host "Enter your UID"
        }
        $Script:password=read-host "Enter your encrypted password"
        while($Script:password -eq ""){
        echo "Encrypted password cannot be null. Please enter a valid input"
        $Script:password=read-host "Enter your encrypted password"
        }
        usePreviousCreds
    } 
    else { usePreviousCreds}
    if(($Script:1_option -match $Script:valid_1_buildFileMenu) -or ($Script:3_option -eq 1) -or ($Script:4_option -eq 2) -or ($Script:4_option -eq 3)) {
        
        if ($Script:1_option -eq 2){$fileType=".gradle"}else{$fileType=".xml"}

$Script:buildFilePath=read-host "Enter build file location (including build file name)"
        while ($Script:buildFilePath.Trim() -eq "" -or !(Test-Path $Script:buildFilePath.Trim()) -or ((Get-Item $Script:buildFilePath.Trim()) -is [System.IO.DirectoryInfo]) -or !($Script:buildFilePath.Contains("$fileType"))) 
        {
            if($Script:buildFilePath -eq "")
            {
                echo "Build file path cannot be empty. Please enter a valid input"
                $Script:buildFilePath=read-host "Enter build file location (including build file name)"
            }
            elseif (!(Test-Path $Script:buildFilePath.Trim()))
            {
                echo "Cannot find specified drive on this system. Please enter build file location from a valid drive`n"
                $Script:buildFilePath=read-host "Enter build file location (including build file name)"
            }

 elseif ((Get-Item $Script:buildFilePath.Trim()) -is [System.IO.DirectoryInfo])
            {
                echo "Path cannot be a directory. Please enter a valid path along with the build file name`n"
                $Script:buildFilePath=read-host "Enter build file location (including build file name)"
            }
            elseif (!($Script:buildFilePath.Contains($fileType)))
            {
                echo "Please enter a file path with $fileType extension `n"
                $Script:buildFilePath=read-host "Enter build file location (including build file name)"
            }
        }
        
        $Script:buildFilePath=$Script:buildFilePath.Trim()
        
    }
    if($Script:main_option -eq 1){searchType}

if($Script:3_option -eq 2) {
        while($Script:local_repo -eq $null) {
            $Script:local_repo_list=read-host "Enter lib folder locations (comma seperated)"
            $myArray = $Script:local_repo_list -split ','
        
            for($i=0; $i -lt $myArray.Count; $i++){
                $Script:local_repo=$myArray[$i]
                validateLocalRepo
            
            }
        }
        $Script:local_repo=$Script:local_repo.Trim()
        #searchType
    }

 if ($Script:1_5_option -eq 1) {
        if (Test-Path C:\Users\$env:username\.m2\repository){
            echo "`n"
            echo "Found default .m2 location - C:\Users\$env:username\.m2\repository"
            echo "Use default .m2 location?"
            $Script:repo_choice=read-host "Enter Y/N"
            
            #while (!($Script:repo_choice -eq "Y" -or $Script:repo_choice -eq "y" -or $Script:repo_choice -eq "N" -or $Script:repo_choice -eq "n" )){
            while($Script:repo_choice -notmatch $Script:yes_no_regex){
                echo "Invalid selection. Please select from Y/N`n"
                $Script:repo_choice=read-host "Enter Y/N"
            }
            if ($Script:repo_choice -eq "Y" -or $Script:repo_choice -eq "y" ) {
                $Script:local_repo = "C:\Users\$env:username\.m2\repository"
            }

 if ($Script:repo_choice -eq "N" -or $Script:repo_choice -eq "n" ) {
                $Script:local_repo=read-host "Enter Maven Local repository location"
            }
        } else {
            echo "Default .m2 folder not found for user - $env:username"
            $Script:local_repo=read-host "Enter Maven Local repository location"
        }
        validateLocalRepo
    }

 if ($Script:1_5_option -eq 2) {
    $Script:local_repo=read-host "`nEnter JAR files location"
    validateLocalRepo
    }
    if ($Script:1_option -eq 4){
    $Script:local_repo=read-host "`nEnter user workspace location"
    validateLocalRepo
    }
    outputLocation
    if(!($Script:main_option -eq 3)){
        outputType
    }
    else{
        if($4_option -eq 1){
            echo "`n"
            $Script:groupId=read-host "Enter groupId"
            while($Script:groupId -eq ""){ 
                echo "GroupId cannot be null. Please enter a valid GroupId`n"
                $Script:groupId=read-host "Enter groupId" 
            }

 $Script:artifactId=read-host "Enter artifactId"
            while($Script:artifactId -eq ""){ 
                echo "ArtifactId cannot be null. Please enter a valid ArtifactId`n"
                $Script:artifactId=read-host "Enter artifactId"
            }
            $Script:version=read-host "Enter version"
            while($Script:version -eq ""){ 
                echo "Version cannot be null. Please enter a valid Version`n"
                $Script:version=read-host "Enter version" 
            }
        
        }
        echo "`n"
        $Script:virtualRepo=read-host "Enter your Virtual repo"
        $hdrEnt = @{ "X-JFrog-Art-Api" = "$global:apikey_etp" }

while ($Script:virtualRepo.Trim() -eq "" -or $Script:aqlMid -eq "") 
        {
            if($Script:virtualRepo.Trim() -eq ""){
            echo "Repo name cannot be empty. Please enter a valid input`n"
            $Script:virtualRepo=read-host "Enter your Virtual repo"
            }
            
            try{
            $repo_result=Invoke-RestMethod -Method GET -Uri "$Script:etp_art_url/api/storage/$virtualRepo" -Headers $hdrEnt
            
                if(!($repo_result.children.Count -eq 0)){
                    $Script:aqlMid = 1
                }
            }
                catch [Exception]{}
                
            if($Script:aqlMid -eq ""){
                    echo "User does not have access to the repo entered. Please enter repo with appropriate access`n"
                    $Script:virtualRepo=read-host "Enter your Virtual repo"
            }
        }
    }

 echo "`n"
    echo "Using output location : $Script:outputDir"
    if($Script:output_type -eq 1){
        $Script:artifact_list = "$outputDir\$app_id"+"_Artifact_List.txt"
    }else {
        $Script:artifact_list = "$outputDir\$app_id"+"_Artifact_List.csv"
    }
}
function outputLocation {
    echo "`n"
    echo "Use default output location? - $PSScriptRoot\output\$app_id"
    $Script:output_choice = read-host "Enter Y/N"
    while ($Script:output_choice.Trim() -eq "" -or !($Script:output_choice -match $Script:yes_no_regex)) 
    {
        if($Script:output_choice.Trim() -eq ""){
        echo "Choice cannot be empty. Please enter a valid input"
        $Script:output_choice=read-host "Enter Y/N"
        }

else {
            echo "Invalid Selection. Please select between Y/N`n"
            $Script:output_choice=read-host "Enter Y/N"
        }
    }
    if ( $output_choice -match $Script:yes_regex) {
        #mkdir $PSScriptRoot\output | Out-Null
        $Script:DependencyReportPath="$PSScriptRoot\output\$app_id"
        
        try{
            # Creating the Output directory as current date and time.
            $Script:outputDir = "$Script:DependencyReportPath\dependency_report_$(get-date -f yyyyMMddHHmm)"
            mkdir $Script:outputDir -ErrorAction SilentlyContinue | Out-Null
            }
            catch [Exception]{
            echo "User does not have Write permissions to this path. Please provide an Output location with Write permissions`n"
            outputLocation
        }

}else{
        $Script:DependencyReportPath=read-host "Enter desired output location"
        $Script:outputDir = "$Script:DependencyReportPath\dependency_report_$(get-date -f yyyyMMddHHmm)"
    }
    while ( $Script:DependencyReportPath -eq "" -or !(Test-Path $Script:DependencyReportPath.Split('\')[0]) -or !(Test-Path $Script:outputDir)) {  
            
     #while ( $Script:DependencyReportPath -eq "" -or !(Test-Path $Script:DependencyReportPath.Trim())) {    
            if ($Script:DependencyReportPath -eq ""){
            echo "Output location cannot be empty. Please enter a valid input`n"
            $Script:DependencyReportPath=read-host "Enter desired output location"
            }
            elseif (!(Test-Path $Script:DependencyReportPath.Split('\')[0])){
            echo "Cannot find specified drive on this system. Please enter an output path from a valid drive`n"
            $Script:DependencyReportPath=read-host "Enter desired output location"
           

}
            elseif(!(Test-Path $Script:outputDir)){
                try{
                # Creating the Output directory as current date and time.
                $Script:outputDir = "$Script:DependencyReportPath\dependency_report_$(get-date -f yyyyMMddHHmm)"
                mkdir $Script:outputDir | Out-Null
                }
                catch [Exception]{
                echo "User does not have Write permissions to this path. Please provide an Output location with Write permissions`n"
                $Script:DependencyReportPath=read-host "Enter desired output location"
                }
            }
        }
}
function outputType {
    echo "`n"
    echo "Select Output Type"
    echo "Enter 1 for Output in TXT format"
    echo "Enter 2 for Output in CSV format"

$Script:output_type = read-host "Select"
    while ($Script:output_type.Trim() -eq "" -or !($Script:output_type -match $Script:option_regex)) 
    {
        if($Script:output_type.Trim() -eq ""){
        echo "Choice cannot be empty. Please enter a valid input"
        $Script:output_type=read-host "Select"
        }
        else {
        echo "Choice should be either 1 or 2. Please enter a valid input"
        $Script:output_type=read-host "Select"
        }
    }  
}

function getLobApiKey {
    
   $global:apikey_lob=read-host "Enter LOB repo api key"
          $Script:auth = $null 
    $hdr = @{ "X-JFrog-Art-Api" = "$global:apikey_lob" } 
    while ($apikey_lob -eq "" -or $Script:auth.Count -eq 0) { 
        try{ $Script:auth=Invoke-RestMethod -Method GET -Uri "$Script:lob_url/api/security/encryptedPassword" -Headers $hdr }
        catch [Exception] {} 
        if($apikey_lob -eq ""){ 
            echo "API Key cannot be empty. Please enter a valid input`n" 
            $global:apikey_lob = $null 
        } 
        elseif ($Script:auth.Count -eq 0) { 
            echo "Unauthorized access to Artifactory. Please enter the API key with appropriate access`n" 
            $global:apikey_lob = $null 
            $Script:auth = $null 
            } 

 if ($global:apikey_lob -eq $null){ 
        $global:apikey_lob=read-host "Enter LOB repo api key"
        $hdr = @{ "X-JFrog-Art-Api" = "$global:apikey_lob" } 
        } 
    }
   
}
############# Dependency extractor #############
function extractBuildDependencies {
    $Script:jarArray = @()
    #For Maven build file
    if($Script:1_option -eq 1) {
        getInputs
        [xml]$pomFile = Get-Content $Script:buildFilePath
        
        set-variable -name line_count -value 0

 foreach($dependency in $pomFile.project.dependencies.dependency) 
        {
            $artifact_data = @{}
            $artifact_data.GroupId =  $dependency.groupId
            $artifact_data.ArtifactId = $dependency.artifactId
            $artifact_data.Version = $dependency.version
            $str4 = $artifact_data.ArtifactId + "-" + $artifact_data.Version +".jar"
            $artifact_data.Sno = ++$line_count;
            $artifact_data.Name = $str4
            $Script:jarArray+=$artifact_data
        } 

foreach( $dependency in $pomFile.project.build.plugins.plugin.dependencies.dependency) 
        { 
            $artifact_data1 = @{}
            $artifact_data1.GroupId =  $dependency.groupId
            $artifact_data1.ArtifactId = $dependency.artifactId
            $artifact_data1.Version = $dependency.version
            $str4 = $artifact_data1.ArtifactId + "-" + $artifact_data1.Version +".jar"
            $artifact_data1.Sno = ++$line_count;
            $artifact_data1.Name = $str4
            $Script:jarArray+=$artifact_data1
        }
    }

#For Gradle build file
    if($Script:1_option -eq 2) {
    
    getInputs
    $regex =  '[A-Za-z0-9.-]+[:]+[A-Za-z0-9.-]+:[A-Za-z0-9.${}]{2,60}'
    $regexGradleConfig =  'compile|testCompile|runtime|testRuntime'
    [regex]$str5 = ":"
    $Values = Get-content -Path $Script:buildFilePath | ?{ $_ -notmatch '//'} | where-object {$_ -match $regexGradleConfig} | select-string -Pattern $regex -AllMatches | % { $_.Matches } | % { $_.Value }
    set-variable -name line_count -value 0
    foreach($str2 in $Values)
        {
        $Script:artifact_data = @{}
        $Script:artifact_data.GroupId =  $str2.split(":")[0]
        $Script:artifact_data.ArtifactId = $str2.split(":")[1]
        $Script:artifact_data.Version = $str2.split(":")[2]

$str4 = $Script:artifact_data.artifactId + "-" + $Script:artifact_data.Version +".jar"
    
        if ($str4.Contains('$')) {
            $artifactId = ($str4.Substring($str4.IndexOf('${project'))).Split(".")[1]
            $gradle = Get-content -Path $Script:buildFilePath
            for ($i=0;$i -lt $gradle.Count; $i++) { 
                if ($gradle[$i].Contains($artifactId+"=[") -or $gradle[$i].Contains($artifactId+" = [") -or $gradle[$i].Contains($artifactId+"= [") -or $gradle[$i].Contains($artifactId+" =[")) { 
                    $version = $gradle[$i+1].Split("'")[1].Trim()
                    #echo version=$version
                    $str4 = $str4.Replace("$" + "{project." + $artifactId + ".version}", $version)
                    $Script:artifact_data.Version = $version
                    #echo artifact=$str4
                }
            }
        }

 $Script:artifact_data.Sno = ++$line_count;
        $Script:artifact_data.Name = $str4
        $Script:jarArray+=$Script:artifact_data
        }
    }
    #For Ant build file
    if(($Script:1_option -eq 3) -or ($Script:3_option -eq 1)) {
        if($Script:1_option -eq 3) {
            getInputs
        }
        [xml]$antBuildFile = Get-content -Path $Script:buildFilePath
        set-variable -name line_count -value 0
        if (($antBuildFile.project.target.javac.classpath.Count -ge 1) -or ($antBuildFile.project.target.javac.classpathref.Count -ge 1)){
            
            for ($i=0; $i -lt $antBuildFile.project.path.pathelement.Count; $i++) {
            if ( !($antBuildFile.project.path.pathelement.location[$i].Contains('jar'))){
                echo "`n"

 echo "Build file contains dependencies referenced from folders\directories"
                echo "`n"
                echo "This format is not supported as we cannot access the folders\directories"
                
                break
            }
            }
        } else {
        foreach($dependency in $antBuildFile.project.target.javac.classpath.pathelement.path) 
        {
            if ( $dependency -match ".jar" )
            {
                $Script:artifact_data = @{}
                $Script:artifact_data.Sno = ++$line_count;
                $Script:artifact_data.Name = $dependency.split("/")[1]
                $Script:artifact_data.GroupId = ""
                $Script:artifact_data.Version = ""
                $regex = '[A-Za-z0-9.-]+-+[0-9.]'
                if($Script:artifact_data.Name -match $regex) {
                    foreach($val in $Script:artifact_data.Name.Split("-")) {

     $Script:artifact_data.Version = $val.Replace(".jar","")
                    }
                    $Script:artifact_data.ArtifactId = $Script:artifact_data.Name.Replace("-"+$Script:artifact_data.Version+".jar", "")
                }else{
                    $Script:artifact_data.ArtifactId = $Script:artifact_data.Name.Replace(".jar","")
                }
                $Script:jarArray+=$Script:artifact_data
            }
        }
      }
      
    }
    if ($Script:output_type -eq 1){
    $Script:jarArray.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name,GroupId,ArtifactId,Version -AutoSize |Out-File -Append -FilePath $artifact_list -Width 4000
    }else {
    $Script:jarArray.ForEach({[PSCustomObject]$_}) | Select-Object Sno,Name,GroupId,ArtifactId,Version|ConvertTo-Csv -NoTypeInformation| Out-File $artifact_list -Encoding ASCII
    }
}

############# Dependency checker #############
function search_artifactory_jar_name ($array, [string] $apiKey,[string] $url, [string] $searchDest){
    
    $hdrEnt = @{ "X-JFrog-Art-Api" = "$apikey" }
    $myvar = $array.Name
    if($searchDest -eq "lob") {
        $test = 'items.find(
    {"name": {"$eq": "' + $myvar + '"}}
)'
    }else{
        $aqlStart = 'items.find(
        {"$or":[{'
        $aqlEnd = '}],"$and":[
        {"name": {"$eq": "' + $myvar + '"}}]}
)'
  
        $test = $aqlStart + $Script:aqlMid.TrimEnd(",") + $aqlEnd
    }

$result = Invoke-RestMethod -Method POST -Uri "$url/api/search/aql" -Headers $hdrEnt -ContentType "text/plain" -Body $test   
    
    if ($result.results.Count -eq "0") {
        $Script:notFound += $array
    }else{
        $Script:available = "false"
        for ($i=0; $i -lt $result.results.Count; $i++) {
            if (!($result.results[$i].repo.Contains('release') -or $result.results[$i].repo.Contains('snapshot'))) {
                
                $mydata = @{}
                $mydata.Sno= $array.Sno
                $mydata.Name = $array.Name
                $mydata.URL = $url+'/'+$result.results[$i].repo+'/'+$result.results[$i].path+'/'+$result.results[$i].name
                $mydata.Path = $result.results[$i].path
                $GAV_test = $url+'/'+$result.results[$i].repo+'/'
                $GAV_test = $mydata.URL.Replace("$GAV_test", " ")
                $GAV_test = $GAV_test.Trim()

 $var = $GAV_test.split('/')
                $name_artifact = $var[-1]
                $mydata.Version =$var[-2]
                $mydata.ArtifactId = $var[-3]
                $temp = "/"+$var[-3]+"/"+$var[-2]+"/"+$var[-1]
                $mydata.GroupId = $GAV_test.Replace($temp,"").Replace("/",".")
                $mydata.GAV = $mydata.GroupId + ":" + $mydata.ArtifactId + ":" + $mydata.Version
                $Script:allInfoArr += $mydata
                #For gradle file option
                $Script:obtainedJarsArray += $mydata
                $Script:available = "true"
            }
        }
        
        if ($Script:available -eq "true") {
            $Script:myarr +=$mydata
        } else {
            $Script:notFound += $array
        }
    }
}

function searchBuildDependencies {
    echo ""
    echo "Checking availablity of URL's"
    echo ""
    accessCheck $Script:etp_art_url
    $Script:flag_etp = $Script:flag
    accessCheck $Script:foss_art_url
    $Script:flag_foss = $Script:flag
    
    if ($1_option -eq "4"){
        $url2="https://www.nuget.org/"
        accessCheck $url2
        $Script:flag_nuget = $Script:flag
    } else{
        $url1="https://search.maven.org/"
        accessCheck $url1
        $Script:flag_maven = $Script:flag
    }

echo "`n"
    echo ***************************************
    echo " Searching for artifacts "
    echo ***************************************
    echo "`n"
    $Script:foss_art_url = "http://cpvra00a0223.wellsfargo.com:8090/artifactory"
    if ($Script:output_type -eq 1){
    $Script:av_dep = "$Script:outputDir\$Script:app_id"+"_Obtained_Artifact_List.txt"
    $Script:un_dep = "$Script:outputDir\$Script:app_id"+"_UnAvailable_Artifact_List.txt"
    $Script:all_info = "$Script:outputDir\$Script:app_id"+"_All_Information.txt"
    $Script:av_dep_lob = "$Script:outputDir\$Script:app_id"+"_Obtained_Artifact_List_LOB.txt"
    }else{
    $Script:av_dep = "$Script:outputDir\$Script:app_id"+"_Obtained_Artifact_List.csv"
    $Script:un_dep = "$Script:outputDir\$Script:app_id"+"_UnAvailable_Artifact_List.csv"
    $Script:all_info = "$Script:outputDir\$Script:app_id"+"_All_Information.csv"
    $Script:av_dep_lob = "$Script:outputDir\$Script:app_id"+"_Obtained_Artifact_List_LOB

.csv"

}

 $Script:notFound = @()
    $Script:un_etp = @()
    $Script:un_foss = @()
    $Script:myarr = @()
    $Script:unavail = @()
    $Script:allInfoArr = @()
    $Script:unObtained = @()
    if($Script:flag_etp -eq 1){
    echo "Searching in Enterprise Artifactory..."
    #if ($Script:output_type -eq 1){
    #echo "Aritfacts found in Enterprise Artifactory:"|Out-File -Append -FilePath $Script:av_dep -Width 4000
    #}else{
    #echo "Aritfacts found in Enterprise Artifactory:"|Out-File -Append -Encoding ascii -FilePath $Script:av_dep
    #}
    
 foreach ($point in $Script:un_etp){
        search_artifactory_jar_name $point $global:apikey_foss $Script:foss_art_url "lob"
    }
        if (!($Script:myarr.Count -eq "0")) {
            if ($Script:output_type -eq 1){
            echo "Aritfacts found in Fossware Artifactory:"|Out-File -Append -FilePath $Script:av_dep -Width 4000
            $Script:myarr.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name -AutoSize |Out-File -Append -FilePath $Script:av_dep -Width 4000
            }else{
            echo "Aritfacts found in Fossware Artifactory:"|Out-File -Append -FilePath $Script:av_dep
            $Script:myarr.ForEach({[PSCustomObject]$_}) | Select-Object Sno,Name| ConvertTo-Csv -NoTypeInformation| Out-File -Append -FilePath $Script:av_dep
            }
        }
    }else{
    $Script:notFound=$Script:un_etp
    }
    $Script:un_foss=$Script:notFound
    $Script:myarr = @()
    $Script:notFound = @()

  if($Script:flag_maven -eq 1){
    echo "Searching for artifacts in Maven Central..."
    #if ($Script:output_type -eq 1){
    #echo ""|Out-File -Append -FilePath $Script:av_dep -Width 4000
    #echo "Aritfacts found in Maven Central:"|Out-File -Append -FilePath $Script:av_dep -Width 4000
    #}else{
    #echo ""|Out-File -Append -FilePath $Script:av_dep
    #echo "Aritfacts found in Maven Central:"|Out-File -Append -FilePath $Script:av_dep
    #}
    
    foreach ($point in $Script:un_foss){
        $groupId = ""
        $artifactId = ""
        $version = ""
        for($i=0;$i-le $Script:jarArray.length-1;$i++) {
    
            if($point.Name -eq $Script:jarArray[$i].Name) {
                $groupId = $Script:jarArray[$i].GroupId
                $artifactId = $Script:jarArray[$i].ArtifactId
                $version = $Script:jarArray[$i].Version
            }
    
        }

  $url="http://search.maven.org/solrsearch/select?q=g:%22" + $groupId + "%22+AND+a:%22" + $artifactId + "%22+AND+v:%22" + $version + "%22&core=gav&rows=20&wt=json"
        $result=(new-object net.webclient).DownloadString($url)
        $json=$result|ConvertFrom-Json
        if (!($json.response.numFound -eq "0")) {
            $mydata = @{}
            $mydata.Sno= $point.Sno
            $mydata.Name = $point.Name
            #$mydata.GAV = $point.GAV
            $mydata.URL = $url
            $Script:myarr += $mydata
            $Script:allInfoArr += $mydata
        }else{
            $Script:unavail += $point
            #$Script:notFound += $point.SHA1
            $mydata = @{}
            $mydata.Sno= $point.Sno
            $mydata.Name = $point.Name
            #$mydata.GAV = $point.GAV
            $mydata.URL = ""
            $Script:unObtained += $mydata
        }
    }

 }else { 
    $Script:unavail += $un_foss 
    }
    
    if (!($Script:myarr.Count -eq "0")) {
        if ($Script:output_type -eq 1){
        echo "Aritfacts found in Maven Central:"|Out-File -Append -FilePath $Script:av_dep -Width 4000
        $Script:myarr.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name -AutoSize |Out-File -Append -FilePath $Script:av_dep -Width 4000
        }else{
        echo "Aritfacts found in Maven Central:"|Out-File -Append -FilePath $Script:av_dep
        $Script:myarr.ForEach({[PSCustomObject]$_}) | Select-Object Sno,Name |ConvertTo-Csv -NoTypeInformation|Out-File -Append -FilePath $Script:av_dep
        }
    }
    $Script:myarr = @()
    $Script:notFound = @()
    echo "`n"
    echo "Search Complete for Enterprise, Foss and Maven Central"

 if(!($Script:unavail.Count -eq "0")) {
        echo "`n"
        echo "Do you wish to search un-obtained artifacts in LOB repo?"
        $Script:is_search_lob=read-host "Enter(y/n)"
        while($Script:is_search_lob -eq "" -or !($Script:is_search_lob -match $Script:yes_no_regex)){
            if($Script:is_search_lob -eq ""){
            echo "Selection cannot be empty`n"
                $Script:is_search_lob=read-host "Enter(y/n)"
            }
            elseif(!($Script:is_search_lob -match $Script:yes_no_regex)){
                echo "Invalid Selection. Please select between Y/N`n"
                $Script:is_search_lob=read-host "Enter(y/n)"
            }
        }
              
        if($Script:is_search_lob -match $Script:no_regex){ echo "`nSkipping search in LOB Artifactory"}

 if($Script:is_search_lob -match $Script:yes_regex) {
            $Script:lob_url=read-host "Enter LOB repo URL (Ex: https://artifactory.dev.cci.wellsfargo.com)"
            $statusCode=0
            while ($Script:lob_url.Trim() -eq "" -or $statusCode -eq 0) 
            {
                if($Script:lob_url.Trim() -eq ""){
                    echo "LOB repo URL cannot be empty. Please enter a valid URL"
                    $Script:lob_url=read-host "Enter LOB repo URL"
                }else{
                    try{ 
                        $output=Invoke-WebRequest -Uri $Script:lob_url
                        $statusCode=1
                        }
                    catch{
                        $statusCode=0
                        echo "LOB repo URL entred is not valid/not responding. Please enter a valid URL"
                        $Script:lob_url=read-host "Enter LOB repo URL"
                    }
                }
            }

    $Script:lob_url = $Script:lob_url.Trim() + "/artifactory"
            getLobApiKey
            echo "`nSearching for artifacts in $Script:lob_url..."
            foreach ($val in $Script:unavail){
                search_artifactory_jar_name $val $global:apikey_lob $Script:lob_url "lob"
            }           
            
            if (!($Script:myarr.Count -eq "0")) {
                if ($Script:output_type -eq 1){
                    echo "Artifacts found in LOB repo :"|Out-File -Append -FilePath $Script:av_dep_lob -Width 4000
                    $Script:myarr.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name,Path,URL -AutoSize |Out-File -Append -FilePath $Script:av_dep_lob -Width 4000
                }else{
                    echo "Artifacts found in LOB repo :"|Out-File -Append -FilePath $Script:av_dep_lob -Encoding ascii
                    $Script:myarr.ForEach({[PSCustomObject]$_}) | Select-Object Sno,Name,Path,URL |ConvertTo-Csv -NoTypeInformation|Out-File -Append -FilePath $Script:av_dep_lob
                }
            }

 if ($Script:output_type -eq 1){
                echo "Artifacts unobtained from Enterprise, FOSS, Maven Central and LOB repo :"|Out-File -Append -FilePath $Script:un_dep -Width 4000
                $Script:notFound.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name -AutoSize |Out-File -Append -FilePath $Script:un_dep -Width 4000
            }else{
                echo "Artifacts unobtained from Enterprise FOSS Maven Central and LOB repo :"|Out-File -Append -FilePath $Script:un_dep -Encoding ascii
                $Script:notFound.ForEach({[PSCustomObject]$_}) | Select-Object Sno,Name |ConvertTo-Csv -NoTypeInformation|Out-File -Append -FilePath $Script:un_dep
            }
            foreach ($data in $Script:notFound){
                $Script:allInfoArr += $data
            }
        }else{
            foreach ($data in $Script:unObtained){
                $Script:allInfoArr += $data
            }

 if ($Script:output_type -eq 1){
                echo "Artifacts unobtained from Enterprise, FOSS and Maven Central:"|Out-File -Append -FilePath $Script:un_dep -Width 4000
                $Script:unavail.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name -AutoSize |Out-File -Append -FilePath $Script:un_dep -Width 4000
            }else{
                echo "Artifacts unobtained from Enterprise FOSS and Maven Central:"|Out-File -Append -FilePath $Script:un_dep -Encoding ascii
                $Script:unavail.ForEach({[PSCustomObject]$_}) | Select-Object Sno,Name|ConvertTo-Csv -NoTypeInformation |Out-File -Append -FilePath $Script:un_dep
            }
        }
    }
    if ($Script:output_type -eq 1){
        $Script:allInfoArr.ForEach({[PSCustomObject]$_}) | sort-Object Sno | Format-Table Sno,Name,URL -AutoSize |Out-File -Append -FilePath $Script:all_info -Width 4000
    }else{

$Script:allInfoArr.ForEach({[PSCustomObject]$_}) | sort-Object Sno | Select-Object Sno,Name,URL|ConvertTo-Csv -NoTypeInformation |Out-File -Append -FilePath $Script:all_info -Encoding ascii
    }
    echo "Searching for alternate artifacts by artifactId:"
    alternateSearch $Script:unavail $Script:un_dep
    echo "`n"
    echo "Search Complete"
    echo "`n"
    echo "Output files are stored at location :"$Script:outputDir
}
############# Dependency checker - Local repo #############

function search_artifactory_SHA1 ($array, [string] $apiKey,[string] $url){
    $hdr = @{ "X-JFrog-Art-Api" = "$apikey" }
    $hash=$array.SHA1
     $aqlStart = 'items.find(
        {"$or":[{'
        $aqlEnd = '}],"$and":[
        {"actual_sha1": {"$eq": "' + $hash + '"}}]}
)'
  
    $test = $aqlStart + $Script:aqlMid.TrimEnd(",") + $aqlEnd
    $result = Invoke-RestMethod -Method POST -Uri "$url/api/search/aql" -Headers $hdr -ContentType "text/plain" -Body $test
    
    if ($result.results.Count -eq "0") {
        $Script:notFound += $array
        $Script:allInfoArr += $array
    }else{

 $Script:available = "false"
        for ($i=0; $i -lt $result.results.Count; $i++) { 
            
            if (!($result.results[$i].repo.Contains('release') -or $result.results[$i].repo.Contains('snapshot'))) {
            
                $mydata = @{}
                $mydata.Sno= $array.Sno
                $mydata.Name = $array.Name       
                $mydata.SHA1 = $array.SHA1
                $mydata.URL = $url+'/'+$result.results[$i].repo+'/'+$result.results[$i].path+'/'+$result.results[$i].name
        
                $GAV_test = $url+'/'+$result.results[$i].repo+'/'
                $GAV_test = $mydata.URL.Replace("$GAV_test", " ")
                $GAV_test = $GAV_test.Trim()
                $var = $GAV_test.split('/')
                $name_artifact = $var[-1]
                $mydata.Version =$var[-2]
                $mydata.ArtifactId = $var[-3]
                $temp = "/"+$var[-3]+"/"+$var[-2]+"/"+$var[-1]
                $mydata.GroupId = $GAV_te

est.Replace($temp,"").Replace("/",".")
                $mydata.GAV = $mydata.GroupId + ":" + $mydata.ArtifactId + ":" + $mydata.Version
                if ($result.results[$i].name -eq $array.Name) {         
                    $Script:NearestMatch = $result.results[$i].name
                }
   
                $Script:allInfoArr += $mydata
                $Script:available = "true"
            }
        }

  if ($Script:available -eq "true") {
            for ($i=0; $i -lt $result.results.Count; $i++) {
            if (!($result.results[$i].repo.Contains('release') -or $result.results[$i].repo.Contains('snapshot'))) {
                if ($Script:NearestMatch -eq $null) {
                    if( [string]$array.Name.Split("-")[0] -eq [string]$result.results[$i].name.Split("-")[0] ) {
                        $Script:NearestMatch = $result.results[$i].name
                      }
                  }
              }
             }
            if ($Script:NearestMatch -eq $null) {
                $Script:NearestMatch = $result.results[0].name
            }
            $mydata.NearestMatch = $Script:NearestMatch
            $Script:myarr += $mydata
        } else {
            $Script:notFound += $array
        }
    }
    $Script:NearestMatch=$null
}

function search_artifactory_SHA1_Local ($array, [string] $apiKey,[string] $url){
    $hdr = @{ "X-JFrog-Art-Api" = "$apikey" }
    $hash=$array.SHA1
    $aql = @"
items.find(
    {"actual_sha1": {"`$eq": "$hash"}}
)
"@
    $result = Invoke-RestMethod -Method POST -Uri "$url/api/search/aql" -Headers $hdr -ContentType "text/plain" -Body $aql   
    
    if ($result.results.Count -eq "0") {
        $Script:notFound += $array
       # $Script:unavail_dll += $array
    } else {
        for ($i=0; $i -lt $result.results.Count; $i++) { 
        $mydata = @{}

$mydata.Sno= $array.Sno
        $mydata.Name = $array.Name       
        $mydata.SHA1 = $array.SHA1
        $mydata.GAV = $array.GAV
        $mydata.URL = $url+'/'+$result.results[$i].repo+'/'+$result.results[$i].path+'/'+$result.results[$i].name
            if ($result.results[$i].name -eq $array.Name) {
            $Script:NearestMatch = $result.results[$i].name
            }
        $Script:allInfoArr += $mydata
        }
        
            for ($i=0; $i -lt $result.results.Count; $i++) {
                if ($Script:NearestMatch -eq $null) {
                    if( [string]$array.Name.Split("-")[0] -eq [string]$result.results[$i].name.Split("-")[0] ) {
                        $Script:NearestMatch = $result.results[$i].name
                      }
                  }
             }
 if ($Script:NearestMatch -eq $null) {
        $Script:NearestMatch = $result.results[0].name
        }
        $mydata.NearestMatch = $Script:NearestMatch
        $Script:myarr += $mydata
    }
       $Script:NearestMatch=$null
}
function search_artifactory_dll ($array, [string] $apiKey,[string] $url){
$hdr = @{ "X-JFrog-Art-Api" = "$apikey" }
$hash=[String] $array.Name
$result=$null
try{
$result=Invoke-RestMethod -Method GET -Uri "$url/api/search/archive?name=$hash" -Headers $hdr -ContentType "text/plain"
}
catch [Exception]{
}

if ($result.results.Count -eq "0") {
        $Script:notFound += $array
    } else {
        for ($i=0; $i -lt $result.results.archiveUris.Count; $i++) { 
        $mydata = @{}
        $mydata.Sno= $array.Sno
        $mydata.Name = $array.Name
        $mydata.SHA1 = $array.SHA1
        $mydata.GAV = $array.GAV
            
            if ($result.results.archiveUris.Count -eq 1){
                $mydata.URL = $result.results.archiveUris
            }else{
                $mydata.URL = $result.results.archiveUris[$i]
            }
        $mydata.NearestMatch = $array.Name
        $Script:allInfoArr += $mydata
        }
    $Script:myarr += $mydata
    }
}

function search_artifactory_alternate ($array, [string] $apiKey,[string] $url,[string] $artifact,[string] $searchType, [string] $found_in){
    $hdr = @{ "X-JFrog-Art-Api" = "$apikey" }
    if ($searchType -eq "equal") { 
        $hash=$artifact
        $aql = @"
items.find(
    {"name": {"`$eq": "$hash"}}
)
"@
    $result_temp = Invoke-RestMethod -Method POST -Uri "$url/api/search/aql" -Headers $hdr -ContentType "text/plain" -Body $aql
    $result=$result_temp.results
    }
    if ($searchType -eq "match1") { 
        $hash="$artifact*jar"
        $aql = @"
items.find(
    {"name": {"`$match": "$hash"}}
)

"@
    $result_temp = Invoke-RestMethod -Method POST -Uri "$url/api/search/aql" -Headers $hdr -ContentType "text/plain" -Body $aql
    $result=$result_temp.results
    }
    if ($searchType -eq "match2") { 
    $hash=$artifact
    for ($j=0;$j -lt 10;$j++){        
    $aql = @"
items.find(
    {"name": {"`$match": "$hash-$j*.jar"}}
)
"@
    $result_temp = Invoke-RestMethod -Method POST -Uri "$url/api/search/aql" -Headers $hdr -ContentType "text/plain" -Body $aql
    $result+=$result_temp.results
    }
    }
        
    $aql = @"
items.find(
    {"name": {"`$match": "$hash"}}
)
"@

     
    
    
    if ($result.Count -eq "0") {
        $Script:notFoundAtr += $array
    } else {
        
        for ($i=0; $i -lt $result.Count; $i++) {
            $mydata = @{}
            $mydata.Sno= $array.Sno
            $mydata.Name = $result[$i].name       
            $mydata.SHA1 = $array.SHA1
            $mydata.GAV = $array.GAV
            $mydata.FoundIn = $found_in
            $mydata.URL = $url+'/'+$result[$i].repo+'/'+$result[$i].path+'/'+$result[$i].name
            $Script:altArr += $mydata
        }
    
      }
}

-----------------------------------------

function searchLocalRepoDependencies {
    
    echo ""
    echo "Checking availablity of URL's"
    echo ""
    accessCheck $Script:etp_art_url
    $Script:flag_etp = $Script:flag
    
    echo "`n"
    echo ***************************************
    echo " Searching for artifacts "
    echo ***************************************
    echo "`n"
    if ($Script:output_type -eq 1){
    $Script:av_dep = "$outputDir\$Script:app_id"+"_Obtained_Artifact_List.txt"
    $Script:un_dep = "$outputDir\$Script:app_id"+"_UnAvailable_Artifact_List.txt"
    $Script:usr_m2_data = "$outputDir\$Script:app_id"+"_User_local_repo_Data.txt"
    $Script:all_info = "$outputDir\$Script:app_id"+"_All_Information.txt"
    }else{

  $Script:av_dep = "$outputDir\$Script:app_id"+"_Obtained_Artifact_List.csv"
    $Script:un_dep = "$outputDir\$Script:app_id"+"_UnAvailable_Artifact_List.csv"
    $Script:usr_m2_data = "$outputDir\$Script:app_id"+"_User_local_repo_Data.csv"
    $Script:all_info = "$outputDir\$Script:app_id"+"_All_Information.csv"
    }
    Remove-Item $Script:av_dep -ErrorAction SilentlyContinue
    Remove-Item $Script:un_dep -ErrorAction SilentlyContinue
    Remove-Item $Script:usr_m2_data -ErrorAction SilentlyContinue
    Remove-Item $Script:all_info -ErrorAction SilentlyContinue
    $Script:line_count = 0
    $Script:alt_count = 0
    $found = @()
    $data = @()
    $Script:notFound = @()
    $Script:myarr = @()
    $Script:allInfoArr = @()
    $sno = 0
    $data1 = @()

 if($Script:3_option -eq 2) {
        $local_repos = $Script:local_repo.Split(",")
        for($i=0; $i -lt $local_repos.Count; $i++) {
            $found += gci -Path $local_repos[$i].Trim() -Recurse -Include "*.jar" -File
        }
    }else{
        #for gradle dependencies file option
        $found = $Script:jarArray
    }
    foreach ($item in $found){  
        $itmdata = @{}
        $itmdata.Sno= ++$sno
        $itmdata.Name = $item.Name
        
        if($Script:3_option -eq 2) {       
            $itmdata.Path = $item.FullName
            $hashobj = Get-FileHash -Path "$($item.FullName)" -Algorithm SHA1
            $itmdata.SHA1 = $hashobj.hash.ToLower()
        }
        $data1 += $itmdata
    }

 if($Script:3_option -eq 2) {
        if ($Script:output_type -eq 1){
        $data1.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name,Path -AutoSize | Out-File -FilePath $usr_m2_data -Width 4000
        }else{
        $data1.ForEach({[PSCustomObject]$_}) | Select-Object Sno,Name,Path|ConvertTo-Csv -NoTypeInformation| Out-File -FilePath $usr_m2_data -Encoding ascii
        }
    }
    if($Script:flag_etp -eq 1){
    echo "Searching in Enterprise Artifactory..."
    
    foreach ($point in $data1){
        if($Script:3_option -eq 2) {
            search_artifactory_SHA1 $point $global:apikey_etp $Script:etp_art_url
        }else{
            search_artifactory_jar_name $point $global:apikey_etp $Script:etp_art_url "lob"
        }
    }

if(!($Script:notFound.Count -eq 0)){
        if ($Script:output_type -eq 1){
        echo "Aritfacts unavailable in Enterprise Artifactory:"|Out-File -Append -FilePath $Script:un_dep -Width 4000
        $Script:notFound.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name -AutoSize |Out-File -Append -FilePath $Script:un_dep -Width 4000
        }else{
        echo "Aritfacts unavailable in Enterprise Artifactory:"|Out-File -Append -FilePath $Script:un_dep -Encoding ascii
        $Script:notFound.ForEach({[PSCustomObject]$_}) | Select-Object Sno,Name|ConvertTo-Csv -NoTypeInformation |Out-File -Append -FilePath $Script:un_dep
        }
    }
    if($Script:3_option -eq 2) {

  if (!($Script:myarr.Count -eq "0")) {
            if ($Script:output_type -eq 1){
            echo "Aritfacts found in Enterprise Artifactory:"|Out-File -Append -FilePath $Script:av_dep -Width 4000
            $Script:myarr.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name,NearestMatch,URL -AutoSize |Out-File -Append -FilePath $Script:av_dep -Width 4000
            }else{
            echo "Aritfacts found in Enterprise Artifactory:"|Out-File -Append -FilePath $Script:av_dep -Encoding ascii
            $Script:myarr.ForEach({[PSCustomObject]$_}) | Select-Object Sno,Name,NearestMatch,URL|ConvertTo-Csv -NoTypeInformation|Out-File -Append -FilePath $Script:av_dep
            }
        }
        if ($Script:output_type -eq 1){
        $Script:allInfoArr.ForEach({[PSCustomObject]$_}) |Sort-Object Sno |Format-Table Sno,Name,SHA1,GAV,URL -AutoSize |Out-File -Append -FilePath $Script:all_info -Width 10000
        }else{

 $Script:allInfoArr.ForEach({[PSCustomObject]$_}) |Sort-Object Sno |Select-Object Sno,Name,SHA1,GAV,URL|ConvertTo-Csv -NoTypeInformation|Out-File -Append -FilePath $Script:all_info -Encoding ascii
        }
    }else{
        if (!($Script:myarr.Count -eq "0")) {
            if ($Script:output_type -eq 1){
            echo "Aritfacts found in Enterprise Artifactory:"|Out-File -Append -FilePath $Script:av_dep -Width 4000
            $Script:myarr.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name,URL -AutoSize |Out-File -Append -FilePath $Script:av_dep -Width 4000
            }else{
            echo "Aritfacts found in Enterprise Artifactory:"|Out-File -Append -FilePath $Script:av_dep -Encoding ascii
            $Script:myarr.ForEach({[PSCustomObject]$_}) | Select-Object Sno,Name,URL|ConvertTo-Csv -NoTypeInformation |Out-File -Append -FilePath $Script:av_dep
            }
        }

  $Script:allInfoArr += $Script:notFound
        if ($Script:output_type -eq 1){
        $Script:allInfoArr.ForEach({[PSCustomObject]$_}) |Sort-Object Sno |Format-Table Sno,Name,GAV,URL -AutoSize |Out-File -Append -FilePath $Script:all_info -Width 10000
        }else{
        $Script:allInfoArr.ForEach({[PSCustomObject]$_}) |Sort-Object Sno |Select-Object Sno,Name,GAV,URL|ConvertTo-Csv -NoTypeInformation |Out-File -Append -FilePath $Script:all_info -Encoding ascii
        }
    }
    
    echo "`n"
    echo "Search Complete"
    
  }else {echo "Could not process search as Enterprise Artifactory is currently down"}
}

function alternateSearch($artifacts, [string] $unDep) {
    if (!($artifacts.Count -eq "0")) {
        
        #if ($Script:output_type -eq 1){
        #echo "*******************************************"|Out-File -Append -FilePath $unDep -Width 4000
        #echo "Alternate artifacts searched by artifactId:"|Out-File -Append -FilePath $unDep -Width 4000
        #echo "*******************************************"|Out-File -Append -FilePath $unDep -Width 4000
        #}else{
        #echo "*******************************************"|Out-File -Append -FilePath $unDep
        #echo "Alternate artifacts searched by artifactId:"|Out-File -Append -FilePath $unDep
        #echo "*******************************************"|Out-File -Append -FilePath $unDep
        #}
    }
    $Script:altArr = @()
    foreach ($alt in $artifacts){


        if(!($Script:1_option -eq "4")) {
            if($alt.Name.Contains("-") -and $alt.Name.Replace(".jar","").Contains('.') -and ($alt.Name.Replace(".jar","").Substring($alt.Name.IndexOf('-')) -match '\d')) {
                $hash=$alt.Name.Replace(".jar","").Substring(0,$alt.Name.IndexOf('.'))
                if($Script:flag_etp -eq 1){
                search_artifactory_alternate $alt $global:apikey_etp $Script:etp_art_url $hash "match1" "Enterprise Artifactory"
                }
                if($Script:flag_foss -eq 1){
                search_artifactory_alternate $alt $global:apikey_foss $Script:foss_art_url $hash "match1" "Fossware Artifactory"
                }
            }else{ 
                $hash=$alt.Name.Replace(".jar","") 
                if($Script:flag_etp -eq 1){
                search_artifactory_alternate $alt $global:apikey_etp $Script:etp_art_url $hash "match2" "Enterprise Artifactory"
                }

 if($Script:flag_foss -eq 1){
                search_artifactory_alternate $alt $global:apikey_foss $Script:foss_art_url $hash "match2" "Fossware Artifactory"
                }
            }
         } else{
            $hash=$alt.Name   
            if($Script:flag_etp -eq 1){
            search_artifactory_alternate $alt $global:apikey_etp $Script:etp_art_url $hash "equal" "Enterprise Artifactory"
            }
            if($Script:flag_foss -eq 1){
            search_artifactory_alternate $alt $global:apikey_foss $Script:foss_art_url $hash "equal" "Fossware Artifactory"
            }
        }
    
    if(!($Script:1_option -eq "4")) {
        if($Script:flag_maven -eq 1){
        $url="http://search.maven.org/solrsearch/select?q=a:"+$hash+"&rows=20&wt=json"
        try{
                $result=(new-object net.webclient).DownloadString($url)
                }
                catch [Exception]{
                $result=$null
                }

      if(!($result -eq $null)){
                $json=$result|ConvertFrom-Json
                }
            if (!($json.response.numFound -eq "0")) {
                $mydata = @{}
                $mydata.Sno= $alt.Sno
                $mydata.Name = $alt.Name       
                $mydata.SHA1 = $alt.SHA1
                $mydata.GAV = $alt.GAV
                $mydata.FoundIn = "Maven Cenrtal"
                $mydata.URL = "http://search.maven.org/#search|ga|1|a:"+$hash.ToLower()
                $Script:altArr += $mydata
            }
        }
    }

  if (!($Script:altArr.Count -eq "0")) {
            #echo "Alternate artifacts for $hash"| Out-File  -Append -FilePath $unDep -Width 4000
            if ($Script:output_type -eq 1){            
            echo "*******************************************"|Out-File -Append -FilePath $unDep -Width 4000
            echo "Alternate artifacts searched by artifactId: $hash"|Out-File -Append -FilePath $unDep -Width 4000
            echo "*******************************************"|Out-File -Append -FilePath $unDep -Width 4000
            $Script:altArr.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name,FoundIn,URL -AutoSize |Out-File -Append -FilePath $unDep -Width 4000
            }else{
            echo "*******************************************"|Out-File -Append -FilePath $unDep

    echo "Alternate artifacts searched by artifactId: $hash"|Out-File -Append -FilePath $unDep
            echo "*******************************************"|Out-File -Append -FilePath $unDep
            $Script:altArr.ForEach({[PSCustomObject]$_}) | Select-Object Sno,Name,FoundIn,URL|ConvertTo-Csv -NoTypeInformation |Out-File -Append -FilePath $unDep
            }
        }
    $Script:altArr = @()  
    }
}
############# Dependency uploader #############
function getUploadInputs {
    echo "`n"
    echo *************************************************
    echo " Preparing folder structure for upload "
    echo *************************************************
    echo "`n"


    $Script:remediate_repo=read-host "Enter remediate repo name (Ex: local-clt-ars-maven-remdiate)"
    $hdrEnt = @{ "X-JFrog-Art-Api" = "$global:apikey_etp" }
    
    while ($Script:remediate_repo.Trim() -eq "" -or $Script:aqlMid -eq "") 
    {
        if($Script:remediate_repo.Trim() -eq ""){
        echo "Repo name cannot be empty. Please enter a valid input"
        $Script:remediate_repo=read-host "Enter remediate repo name (Ex: local-clt-ars-maven-remdiate)"
        }
        
        try{
        $repo_result=Invoke-RestMethod -Method GET -Uri "$Script:etp_art_url/api/storage/$remediate_repo" -Headers $hdrEnt
        
            if(!($repo_result.children.Count -eq 0)){
                $Script:aqlMid = 1
            }
        }
            catch [Exception]{}
            
  if($Script:aqlMid -eq ""){
                echo "User does not have access to the repo entered. Please enter repo with appropriate access`n"
                $Script:remediate_repo=read-host "Enter remediate repo name (Ex: local-clt-ars-maven-remdiate)"
        }
    }
}
function getLobUploadInputs {
    
    $statusCode=0
            $Script:lob_url=read-host "Enter LOB repo URL (Ex: https://artifactory.dev.cci.wellsfargo.com)"
            while ($Script:lob_url.Trim() -eq "" -or $statusCode -eq 0) 
            {
                if($Script:lob_url.Trim() -eq ""){
                    echo "LOB repo URL cannot be empty. Please enter a valid URL"
                    $Script:lob_url=read-host "Enter LOB repo URL"
                }else{
                    try{ 
                        $output=Invoke-WebRequest -Uri $Script:lob_url
                        $statusCode=1
                        }

catch{
                        $statusCode=0
                        echo "LOB repo URL entred is not valid/not responding. Please enter a valid URL"
                        $Script:lob_url=read-host "Enter LOB repo URL"
                    }
                }
            }
            
    $Script:lob_url = $Script:lob_url.Trim() + "/artifactory"
    getLobApiKey
    $Script:obtainedLobListPath = Read-Host 'Enter LOB obtained list file location (including filename)'
    while ($Script:obtainedLobListPath.Trim() -eq "") {
        echo "Lob file location cannot be empty"
        $Script:obtainedLobListPath=read-host "Enter LOB obtained list file location (including filename)"
    }
    $Script:obtainedLobListPath = $Script:obtainedLobListPath.Trim()
}

function readExcelForJarPath {
    $Script:dependencyExcelPath=read-host "Enter dependency excel location (including excel file name)"
         while ($Script:dependencyExcelPath.Trim() -eq "" -or !(Test-Path $Script:dependencyExcelPath.Trim())) 
             {
            if($Script:dependencyExcelPath -eq "")
            {
            echo "Dependency excel location path cannot be empty. Please enter a valid input"
            $Script:dependencyExcelPath=read-host "Enter dependency excel location (including excel file name)"
            }
            elseif (!(Test-Path $Script:dependencyExcelPath.Trim()))
            {
            echo "Cannot find specified drive on this system. Please enter dependency excel location from a valid drive`n"
            $Script:dependencyExcelPath=read-host "Enter dependency excel location (including excel file name)"
            }
            }
        $Script:dependencyExcelPath=$Script:dependencyExcelPath.Trim()

$Script:dependencyJarPath=read-host "Enter dependency artifacts location"
    while ($Script:dependencyJarPath.Trim() -eq "" -or !(Test-Path $Script:dependencyJarPath.Trim())) 
             {
            if($Script:dependencyJarPath -eq "")
            {
            echo "Dependency artifacts location path cannot be empty. Please enter a valid input"
            $Script:dependencyJarPath=read-host "Enter dependency artifacts location"
            }
            elseif (!(Test-Path $Script:dependencyJarPath.Trim()))
            {
            echo "Cannot find specified drive on this system. Please enter dependency artifacts location from a valid drive`n"
            $Script:dependencyJarPath=read-host "Enter dependency artifacts location"
            }
            }
    $Script:dependencyJarPath=$Script:dependencyJarPath.Trim()

  echo "`n"
    echo "Preparing for local artifacts upload..."
    $SheetName = "Sheet1"
    $objExcel = New-Object -ComObject Excel.Application
    $objExcel.Visible = $False
    $Workbook = $objExcel.Workbooks.open($Script:dependencyExcelPath)
    $Worksheet = $Workbook.sheets.item($SheetName)
    $startRow = 2
    $rowCount = ($Worksheet.UsedRange.Rows).count
    for($startRow=2; $startRow -le $rowCount; $startRow++)
    {
        $artifactDets = @{}
        $path = $Worksheet.Cells.Item($startRow, 1).Value()
        $gav = $path.Split("/")

 $artifactDets.JarName = $gav[$gav.Count - 1]
        $artifactDets.Path = $path.Replace("/"+$artifactDets.JarName, "")
        $artifactDets.Source = $Script:dependencyJarPath + "\" + $artifactDets.JarName
        
        $gav = $artifactDets.Path.Split("/")
        $artifactDets.GroupId = ""
        $artifactDets.ArtifactId = ""
        $artifactDets.Version = ""
        
        if($gav.Count -ge "3") {
            $artifactDets.Version = $gav[$gav.Count - 1]
            $artifactDets.ArtifactId = $gav[$gav.Count - 2]
            
            [int]$x = 0
            while($x -le ($gav.Count-3)) {
                $artifactDets.GroupId = $artifactDets.GroupId + $gav[$x] + "."
                $x = $x + 1
            }
            $artifactDets.GroupId = ($artifactDets.GroupId).TrimEnd(".")

 }elseif($gav.Count -eq "2"){
            $artifactDets.ArtifactId = $gav[$gav.Count - 2]
            $artifactDets.Version = $gav[$gav.Count - 1]
        }elseif($gav.Count -eq "1"){
            $artifactDets.ArtifactId = $gav[$gav.Count - 1]
            #$artifactDets.Version = $(get-date -f yyyyMMddHHmmss)
        }
        
        $artifactDets.PomName = ($artifactDets.JarName).Replace(".jar", ".pom")
        $Script:pathArray += $artifactDets
    }
}

function downloadLobJars ($url, $jarName) {
    $hdrEnt = @{ "X-JFrog-Art-Api" = "$global:apikey_lob" }
    Invoke-RestMethod -Method GET -Uri $url -Headers $hdrEnt -OutFile "$Script:dependencyJarPath\$jarName"
}
function copyJar ($source, $destination) {
    Copy-Item $source $destination
}
function readLobListForJarPath {
    getLobUploadInputs
    echo "`n"
    echo "Preparing for LOB artifacts upload..."
    $jarPathArray = Get-Content $Script:obtainedLobListPath | select -Skip 4

 foreach($pathVar in $jarPathArray)
    {
        $artifact_data = @{}
        $pathVar=$pathVar -replace '\s+', ' '
        $var=$pathVar.split(" ")
        $artifact_data.JarName=$var[2]
        $artifact_data.Path=$var[3]
        $artifact_data.PomName=""
        $artifact_data.Source = $Script:dependencyJarPath + "\" + $artifact_data.JarName
        $artifact_data.GroupId = ""
        $artifact_data.ArtifactId = ""
        $artifact_data.Version = ""
       
        if(!($artifact_data.JarName -eq $null) -or !($artifact_data.Path -eq $null)) {     
            downloadLobJars $var[4] $artifact_data.JarName   
            $gav = ($artifact_data.Path).Split("/")
            
            if($gav.Count -ge "3") {
                $artifact_data.Version = $gav[$gav.Count - 1]
                $artifact_data.ArtifactId = $gav[$gav.Count - 2]
            
                [int]$x = 0


                while($x -le ($gav.Count-3)) {
                    $artifact_data.GroupId = $artifact_data.GroupId + $gav[$x] + "."
                    $x = $x + 1
                }
                $artifact_data.GroupId = ($artifact_data.GroupId).TrimEnd(".")
            }
            
            if($gav.Count -eq "2") {
                $artifact_data.GroupId = $gav[$gav.Count - 2]
                $artifact_data.ArtifactId = $gav[$gav.Count - 2]
                $artifact_data.Version = $gav[$gav.Count - 1]
            }
            if($gav.Count -eq "1") {
                $artifact_data.GroupId = $gav[$gav.Count - 1]
                $artifact_data.ArtifactId = $gav[$gav.Count - 1]
                $artifact_data.Version = $(get-date -f yyyyMMddHHmmss)
                $artifact_data.JarName = ($artifact_data.JarName).Replace(".jar", "-" + $artifact_data.Version + ".jar")
            }

  $artifact_data.Path = $artifact_data.GroupId + "/" + $artifact_data.ArtifactId + "/" + $artifact_data.Version
            $artifact_data.PomName=($artifact_data.JarName).Replace(".jar",".pom")
            $Script:pathArray+=$artifact_data
        }
    }
}
function readLocalJarsForUpload {
    echo "`n"
    echo "Preparing for local artifacts upload..."
    foreach($jar in $Script:notFound)
    {
        $artifactDets = @{}
        $artifactDets.JarName = $jar.Name
        $artifactDets.PomName = $jar.Name.Replace(".jar",".pom")
        $dets = $jar.Name.Split("-")

 $artifactDets.GroupId = $Script:groupId_default;
        $artifactDets.Version = $(get-date -f yyyyMMddHHmmss)
        $artifactDets.Source = $jar.Path
        if($dets.Count -gt 1) {
            $artifactDets.Version = ($dets[$dets.Count - 1]).Replace(".jar","")
            $artifactDets.ArtifactId = $jar.Name.Replace("-"+$artifactDets.Version+".jar", "")
            $artifactDets.Path = ($artifactDets.GroupId).Replace(".","/") + "/" + $artifactDets.ArtifactId + "/" + $artifactDets.Version
        }else{
            $artifactDets.ArtifactId = ($dets[$dets.Count - 1]).Replace(".jar","")
            $artifactDets.Path = ($artifactDets.GroupId).Replace(".","/") + "/" + $artifactDets.ArtifactId + "/" + $artifactDets.Version
            #renaming jar and pom
            $artifactDets.JarName = ($artifactDets.JarName).Replace(".jar", "-" + $artifactDets.Version + ".jar")
            $artifactDets.PomName = ($artifactDets.PomName).Replace(".pom", "-" + $artifactDets.Version + 

 ".pom")            
        }
        $Script:pathArray += $artifactDets
    }
}
function generatePomDependency ([string] $groupId, [string] $artifactId, [string] $version, [string] $destination){
    #(Get-Content $PSScriptRoot\sample.pom).replace('$groupId', $groupId).replace('$artifactId', $artifactId).replace('$version', $version) | Set-Content $destination
    Set-Content -Path $destination "<?xml version=""1.0"" encoding=""UTF-8""?>
<project xmlns=""http://maven.apache.org/POM/4.0.0""
    xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance""
    xsi:schemaLocation=""http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd"">
  <modelVersion>4.0.0</modelVersion>
  <groupId>$groupId</groupId>
  <artifactId>$artifactId</artifactId>
  <version>$version</version>
</project>"
}


function createFolderStructure ($pathArray) {
    echo "`n"
    echo "Creating folder structure for upload..."
    foreach($path in $pathArray) {
        $jarName = $path.JarName
        $gavPath = $path.Path
        $dest = "$Script:repoDirPath\$Script:remediate_repo\$gavPath"
        $dest = $dest.Replace("/", "\")
        mkdir $dest -ErrorAction SilentlyContinue | Out-Null
        $pomName = $path.PomName
        $source = $path.Source
        
        copyJar $source "$dest\$jarName"
        if($jarName.Contains(".jar")) {
            generatePomDependency $path.GroupId $path.ArtifactId $path.Version "$dest\$pomName"
        }
    }
}

function uploadToEnterpriseArtifactory ($pathArray) {
    echo "`n"
    echo "Uploading artifacts to Enterprise Artifactory..."
    $hdrEnt = @{ "X-JFrog-Art-Api" = "$global:apikey_etp" }
    #$pathArray
    foreach($path in $pathArray) {
        $jarName = $path.JarName
        $gavPath = $path.Path
        $uploadRepoDir = "$Script:repoDirPath\$Script:remediate_repo\$gavPath"
        $uploadRepoDir = $uploadRepoDir.Replace("/", "\")
        mkdir $uploadRepoDir -ErrorAction SilentlyContinue | Out-Null
        $source = $Script:dependencyJarPath+"\"+$jarName
        copyJar $source $uploadRepoDir
        $url = $Script:etp_art_url + "/" + $Script:remediate_repo + "/" + $gavPath + "/" + $jarName
 
        Invoke-RestMethod -Method PUT -Uri $url -Headers $hdrent -InFile "$uploadRepoDir\$jarName" | Out-Null
        if(!($path.PomName -eq "")) {
            $pom = $path.PomName
 $url = $Script:etp_art_url + "/" + $Script:remediate_repo + "/" + $gavPath + "/" + $pom
            Invoke-RestMethod -Method PUT -Uri $url -Headers $hdrent -InFile "$uploadRepoDir\$pom" | Out-Null
        }
    }
    
}
function uploadDependencies {
    $Script:pathArray = @()
    $Script:dependencyJarPath = ""
    if($Script:main_option -eq 2) {
        getInputs
    }
    getUploadInputs
    echo "`n"
    $uploadUnObtainedJars = read-host "Do you wish to upload missing Artifacts from local? Select (y/n)"
    while ($uploadUnObtainedJars.Trim() -eq "" -or !($uploadUnObtainedJars -match $Script:yes_no_regex)) {
        if($uploadUnObtainedJars.Trim() -eq ""){

echo "Selection cannot be empty"
        $uploadUnObtainedJars=read-host "Do you wish to upload missing Artifacts from local? Select (y/n)"
        }
        else {
            echo "Invalid Selection. Please select between Y/N`n"
        $uploadUnObtainedJars=read-host "Do you wish to upload missing Artifacts from local? Select (y/n)"
        }
    }
    $uploadUnObtainedJars=$uploadUnObtainedJars.Trim()
    #For upload from excel or lob repo
    if($Script:main_option -eq 2) {
        if($uploadUnObtainedJars -match $yes_regex) {
            readExcelForJarPath
        }
        else {
        echo "Based on your selection, the missing artifacts will not be uploaded from local."
        }

 echo "`n"
        $uploadLOBJars = read-host "Do you wish to upload LOB artifacts? Select (y/n)"
        while ($uploadLOBJars.Trim() -eq "" -or !($uploadLOBJars -match $Script:yes_no_regex)) {
        if($uploadLOBJars.Trim() -eq ""){
           echo "Selection cannot be empty"
            $uploadLOBJars=read-host "Do you wish to upload LOB artifacts? Select (y/n)"
            }
           else {
            echo "Invalid Selection. Please select between Y/N`n"
            $uploadLOBJars=read-host "Do you wish to upload LOB artifacts? Select (y/n)"
           }
        }
        $uploadLOBJars = $uploadLOBJars.Trim()
        if($uploadLOBJars -match $yes_regex) {
            
            if ($Script:dependencyJarPath -eq "") {
                $Script:dependencyJarPath=read-host "Enter download location for dependency Jars from LOB"
             while ($Script:dependencyJarPath.Trim() -eq "" -or !(Test-Path $Script:dependencyJarPath.Trim())) 
             {

if($Script:dependencyJarPath -eq "")
            {
            echo "Download location path cannot be empty. Please enter a valid input"
            $Script:dependencyJarPath=read-host "Enter download location for dependency Jars from LOB"
            }
            elseif (!(Test-Path $Script:dependencyJarPath.Trim()))
            {
            echo "Cannot find specified drive on this system. Please enter download location from a valid drive`n"
            $Script:dependencyJarPath=read-host "Enter download location for dependency Jars from LOB"
            }
            }
            $Script:dependencyJarPath=$Script:dependencyJarPath.Trim()
            }
        
            readLobListForJarPath
        }
        else{
        echo "Based on your selection, LOB artifacts will not be uploaded."
        }

 if(($uploadUnObtainedJars -match $yes_regex) -or ($uploadLOBJars -match $yes_regex)) {
            $Script:repoDirPath = $Script:outputDir
            createFolderStructure $pathArray
            #Zip repo folder
            #Compress-Archive -Path "$Script:repoDirPath\$Script:remediate_repo" -DestinationPath "$Script:repoDirPath\$Script:remediate_repo.zip"
            uploadToEnterpriseArtifactory $pathArray
            echo "`n"
            echo "Upload Complete"
            echo "`n"
            $msg = "Artifacts uploaded successfully at " + $Script:etp_art_url + "/" + $Script:remediate_repo
            echo $msg
            echo "`n"
            echo "Output files are stored at location :"$outputDir
        }
    }

#For lib option upload
    if($Script:3_option -eq 2) {
        if($uploadUnObtainedJars -match $yes_regex) {
            readLocalJarsForUpload
            $Script:repoDirPath = $Script:outputDir
            createFolderStructure $pathArray
            #Zip repo folder
            #Compress-Archive -Path "$Script:repoDirPath\$Script:remediate_repo" -DestinationPath "$Script:repoDirPath\$Script:remediate_repo.zip"
            uploadToEnterpriseArtifactory $pathArray
            echo "`n"
            echo "Upload Complete"
            echo "`n"
            $msg = "Artifacts uploaded successfully at " + $Script:etp_art_url + "/" + $Script:remediate_repo
            echo $msg
        }else{
            echo "`n"
            echo "Warning! Found unobtained artifacts. Please verify the repo name and upload all dependencies to artifactory to create gradle dependencies file."
            #echo "`n"

  #echo "Output files are stored at location :"$Script:outputDir
            $Script:createGradle = "false"
        }
    }
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}
function dependenciesFromLocalRepo {
    getInputs
    echo ""
    echo "Checking availablity of URL's"
    echo ""
    accessCheck $Script:etp_art_url
    $Script:flag_etp = $Script:flag
    accessCheck $Script:foss_art_url
    $Script:flag_foss = $Script:flag

if ($1_option -eq "4"){
    $url2="https://www.nuget.org/"
    accessCheck $url2
    $Script:flag_nuget = $Script:flag
    }else{
    $url1="https://search.maven.org/"
    accessCheck $url1
    $Script:flag_maven = $Script:flag
    }
    if ($Script:output_type -eq 1){
    $Script:av_dep = "$Script:outputDir\$Script:app_id"+"_Obtained_Artifact_List.txt"
    $Script:un_dep = "$Script:outputDir\$Script:app_id"+"_UnAvailable_Artifact_List.txt"
    $Script:usr_m2_data = "$Script:outputDir\$Script:app_id"+"_User_local_repo_Data.txt"
    $Script:all_info = "$Script:outputDir\$Script:app_id"+"_All_Information.txt"
    $Script:av_dep_lob = "$Script:outputDir\$Script:app_id"+"_Obtained_Artifact_List_LOB.txt"
    }else{

 $Script:av_dep = "$Script:outputDir\$Script:app_id"+"_Obtained_Artifact_List.csv"
    $Script:un_dep = "$Script:outputDir\$Script:app_id"+"_UnAvailable_Artifact_List.csv"
    $Script:usr_m2_data = "$Script:outputDir\$Script:app_id"+"_User_local_repo_Data.csv"
    $Script:all_info = "$Script:outputDir\$Script:app_id"+"_All_Information.csv"
    $Script:av_dep_lob = "$Script:outputDir\$Script:app_id"+"_Obtained_Artifact_List_LOB.csv"
    }
    foreach ($item in $found){
        $itmdata = @{}
        $itmdata.Sno= ++$sno
        $itmdata.Name = $item.Name       
        $itmdata.Path = $item.FullName
        $hashobj = Get-FileHash -Path "$($item.FullName)" -Algorithm SHA1

 if ($1_5_option -eq "1") {
            if (Test-Path $item.FullName.Replace(".jar",".pom")){
                [xml]$gav=Get-Content $item.FullName.Replace(".jar",".pom")
                if (!($gav.project.groupId -eq $null -or $gav.project.artifactId -eq $null -or $gav.project.version -eq $null)){
                    $itmdata.GAV = [string]$gav.project.groupId+':'+[string]$gav.project.artifactId+':'+[string]$gav.project.version
                }
                elseif(!($gav.project.parent.groupId -eq $null -or $gav.project.parent.artifactId -eq $null -or $gav.project.parent.version -eq $null)){
                    $itmdata.GAV = [string]$gav.project.parent.groupId+':'+[string]$gav.project.parent.artifactId+':'+[string]$gav.project.parent.version
                } else {$itmdata.GAV = $null}
            } else {$itmdata.GAV = $null}
        } else {$itmdata.GAV = $null}
        if (!($item.Name.ToLower().EndsWith('dll'))) {

 $itmdata.SHA1 = $hashobj.hash.ToLower()
        }else {$itmdata.SHA1 = $null}
        $Script:data += $itmdata
    }
    
    if ($Script:output_type -eq 1){
    $Script:data.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name,Path -AutoSize | Out-File -FilePath $Script:usr_m2_data -Width 4000
    }else{
    $Script:data.ForEach({[PSCustomObject]$_}) | Select-Object Sno,Name,Path|ConvertTo-Csv -NoTypeInformation| Out-File -FilePath $Script:usr_m2_data -Encoding ascii
    }
    if($Script:flag_etp -eq 1){
    echo "Searching in Enterprise Artifactory:"
    if($Script:search_type -eq 2){
        foreach ($point in $Script:data){

   if ($point.Name.ToLower().EndsWith('dll')) { search_artifactory_dll $point $global:apikey_etp $Script:etp_art_url }
            else { search_artifactory_SHA1 $point $global:apikey_etp $Script:etp_art_url }
        }
    }else{
        foreach ($point in $Script:data){
            if ($point.Name.ToLower().EndsWith('dll')) { search_artifactory_dll $point $global:apikey_etp $Script:etp_art_url }
            else { search_artifactory_SHA1_Local $point $global:apikey_etp $Script:etp_art_url }
        }
    }
    
    
    if (!($Script:myarr.Count -eq "0")) {
        if ($Script:output_type -eq 1){

 echo "Aritfacts found in Enterprise Artifactory:"|Out-File -Append -FilePath $Script:av_dep -Width 4000
        $Script:myarr.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name,NearestMatch -AutoSize |Out-File -Append -FilePath $av_dep -Width 4000
        }else{
        echo "Aritfacts found in Enterprise Artifactory:"|Out-File -Append -FilePath $Script:av_dep -Encoding ascii
        $Script:myarr.ForEach({[PSCustomObject]$_}) | Select-Object Sno,Name,NearestMatch|ConvertTo-Csv -NoTypeInformation |Out-File -Append -FilePath $av_dep
        }
    }
    } else {
    $Script:notFound=$Script:data
    }
    $Script:un_etp=$Script:notFound
    $Script:myarr = @()
    $Script:notFound = @()
    if($Script:flag_foss -eq 1){
    echo "Searching in Fossware Artifactory:"

 foreach ($point in $Script:un_etp){
        if ($point.Name.ToLower().EndsWith('dll')) { search_artifactory_dll $point $global:apikey_foss $Script:foss_art_url 
        
        }
        else{ search_artifactory_SHA1_Local $point $global:apikey_foss $Script:foss_art_url }
    }
    
    if (!($Script:myarr.Count -eq "0")) {
        
        if ($Script:output_type -eq 1){
        echo "Aritfacts found in Fossware Artifactory:"|Out-File -Append -FilePath $Script:av_dep -Width 4000
        $Script:myarr.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name,NearestMatch -AutoSize |Out-File -Append -FilePath $Script:av_dep -Width 4000
        }else{
        echo "Aritfacts found in Fossware Artifactory:"|Out-File -Append -FilePath $Script:av_dep
        $Script:myarr.ForEach({[PSCustomObject]$_}) |Select-Object Sno,Name,NearestMatch|ConvertTo-Csv -NoTypeInformation|Out-File -Append -FilePath $Script:av_dep
        }
    }

 } else {
    $Script:notFound=$Script:un_etp
    }
    $Script:un_foss=$Script:notFound
    $Script:myarr = @()
    $Script:notFound = @()
  if($1_option -eq "4"){
    if($Script:flag_nuget -eq 1){
    echo "Searching in Nuget Gallery:"
    $temp = $outputDir+"\temp"
    mkdir $temp -ErrorAction SilentlyContinue | Out-Null
     foreach ($point in $un_foss){
        $var=$point.Name
        $url="https://api.nuget.org/packages/$var"
       # $result=(new-object net.webclient).DownloadString($url)
        try{
        $statusCode=0
        Invoke-WebRequest -Uri $url -OutFile $temp\$var} 
        catch {
        $statusCode= $_.Exception.Response.StatusCode.Value__
         }
         if($statusCode -eq "0"){
            $mydata = @{}

 $mydata.Sno= $point.Sno
            $mydata.Name = $point.Name       
            $mydata.SHA1 = $point.SHA1
            $mydata.NearestMatch = $point.Name
            $mydata.GAV = $null
            $mydata.URL = $url
            $Script:myarr += $mydata
            $Script:allInfoArr += $mydata
         } else {
                $Script:unavail += $point
                $mydata = @{}
                $mydata.Sno= $point.Sno
                $mydata.Name = $point.Name       
                $mydata.SHA1 = $point.SHA1
                $mydata.GAV = $null
                $mydata.URL = ""
                #$Script:allInfoArr += $mydata
            }
     }
     Remove-Item -Recurse -Force $temp
     }else { 
        $Script:unavail += $un_foss
        #$Script:allInfoArr += $un_foss  
    } 

if (!($myarr.Count -eq "0")) {
        if ($Script:output_type -eq 1){
        echo "Aritfacts found in Nuget.org:"|Out-File -Append -FilePath $av_dep -Width 4000
        $myarr.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name,NearestMatch -AutoSize |Out-File -Append -FilePath $Script:av_dep -Width 4000
        $myarr = $null
        }else{
        echo "Aritfacts found in Nuget.org:"|Out-File -Append -FilePath $av_dep
        $myarr.ForEach({[PSCustomObject]$_}) |Select-Object Sno,Name,NearestMatch|ConvertTo-Csv -NoTypeInformation |Out-File -Append -FilePath $Script:av_dep
        }
        $myarr = $null
    }
    
    } else {
      
    if($Script:flag_maven -eq 1){
    echo "Searching in Maven Central:"
    foreach ($point in $Script:un_foss){

$url="http://search.maven.org/solrsearch/select?q=1:"+$point.SHA1+"&rows=20&wt=json"
        $result=(new-object net.webclient).DownloadString($url)
        $json=$result|ConvertFrom-Json
        if (!($json.response.numFound -eq "0")) {
            $mydata = @{}
            $mydata.Sno= $point.Sno
            $mydata.Name = $point.Name       
            $mydata.SHA1 = $point.SHA1
            $mydata.GAV = $point.GAV
            $mydata.URL = $url
            $mydata.NearestMatch = $json.response.docs.id.Split(':')[1]+"-"+$json.response.docs.id.Split(':')[2]+".jar"
            $Script:myarr += $mydata
            $Script:allInfoArr += $mydata
        } else {
                $Script:unavail += $point
                $mydata = @{}
                $mydata.Sno= $point.Sno
                $mydata.Name = $point.Name       

     $mydata.SHA1 = $point.SHA1
                $mydata.GAV = $point.GAV
                $mydata.URL = ""
                #$Script:allInfoArr += $mydata
            }
    }
    
    }else { 
    $Script:unavail += $Script:un_foss 
    #$Script:allInfoArr += $Script:un_foss 
    } 
    if (!($Script:myarr.Count -eq "0")) {
        
        if ($Script:output_type -eq 1){
        echo "Aritfacts found in Maven Central:"|Out-File -Append -FilePath $Script:av_dep -Width 4000
        $Script:myarr.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name,NearestMatch -AutoSize |Out-File -Append -FilePath $Script:av_dep -Width 4000
        $myarr = $null

}else{
        echo "Aritfacts found in Maven Central:"|Out-File -Append -FilePath $Script:av_dep
        $Script:myarr.ForEach({[PSCustomObject]$_}) |Select-Object Sno,Name,NearestMatch|ConvertTo-Csv -NoTypeInformation |Out-File -Append -FilePath $Script:av_dep
        }
    }
}
    $Script:myarr = @()
    $Script:notFound = @()
    
    if(!($Script:unavail.Count -eq "0")) {
        echo "`n"
        echo "Do you wish to search un-obtained artifacts in LOB repo?"
        $Script:is_search_lob=read-host "Enter(y/n)"
        while($Script:is_search_lob -eq "" -or !($Script:is_search_lob -match $Script:yes_no_regex)){
            if($Script:is_search_lob -eq ""){
            echo "Selection cannot be empty`n"
                $Script:is_search_lob=read-host "Enter(y/n)"
            }


            elseif(!($Script:is_search_lob -match $Script:yes_no_regex)){
                echo "Invalid Selection. Please select between Y/N`n"
                $Script:is_search_lob=read-host "Enter(y/n)"
            }
        }
              
        if($Script:is_search_lob -match $Script:no_regex){ echo "Skipping search in LOB Artifactory`n"}
        if($Script:is_search_lob -match $Script:yes_regex) {
            $statusCode=0
            $Script:lob_url=read-host "Enter LOB repo URL (Ex: https://artifactory.dev.cci.wellsfargo.com)"
            while ($Script:lob_url.Trim() -eq "" -or $statusCode -eq 0) 
            {

if($Script:lob_url.Trim() -eq ""){
                    echo "LOB repo URL cannot be empty. Please enter a valid URL"
                    $Script:lob_url=read-host "Enter LOB repo URL"
                }else{
                    try{ 
                        $output=Invoke-WebRequest -Uri $Script:lob_url
                        $statusCode=1
                        }
                    catch{
                        $statusCode=0
                        echo "LOB repo URL entred is not valid/not responding. Please enter a valid URL"
                        $Script:lob_url=read-host "Enter LOB repo URL"
                    }
                }
            }
            $Script:lob_url = $Script:lob_url.Trim() + "/artifactory"


            getLobApiKey
            echo "`n"
            echo "Searching for artifacts in $Script:lob_url...`n"
            #foreach ($val in $Script:unavail){
            
                if($Script:search_type -eq 2){
                    foreach ($val in $Script:unavail){            
                        if ($val.Name.ToLower().EndsWith('dll')) { search_artifactory_dll $val $global:apikey_lob $Script:lob_url }
                        else { search_artifactory_SHA1 $val $global:apikey_lob $Script:lob_url }
                    }
                }else{
                    foreach ($val in $Script:unavail){
                        if ($val.Name.ToLower().EndsWith('dll')) { search_artifactory_dll $val $global:apikey_lob $Script:lob_url }
                        else { search_artifactory_SHA1_Local $val $global:apikey_lob $Script:lob_url }
                    }
                }

 #search_artifactory_SHA1 $val $global:apikey_lob $Script:lob_url
            #}           
            
            
            if (!($Script:myarr.Count -eq "0")) {
                if ($Script:output_type -eq 1){
                    echo "Artifacts found in LOB repo :"|Out-File -Append -FilePath $Script:av_dep_lob -Width 4000
                    $Script:myarr.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name,Path,URL -AutoSize |Out-File -Append -FilePath $Script:av_dep_lob -Width 4000
                }else{
                    echo "Artifacts found in LOB repo :"|Out-File -Append -FilePath $Script:av_dep_lob -Encoding ascii
                    $Script:myarr.ForEach({[PSCustomObject]$_}) | Select-Object Sno,Name,Path,URL |ConvertTo-Csv -NoTypeInformation|Out-File -Append -FilePath $Script:av_dep_lob
                }
            }
            
            if (!($Script:notFound.Count -eq "0")) {
                if ($Script:output_type -eq 1){

echo "Artifacts unobtained from Enterprise, FOSS, Maven Central and LOB repo :"|Out-File -Append -FilePath $Script:un_dep -Width 4000
                    $Script:notFound.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name -AutoSize |Out-File -Append -FilePath $Script:un_dep -Width 4000
                }else{
                    echo "Artifacts unobtained from Enterprise FOSS Maven Central and LOB repo :"|Out-File -Append -FilePath $Script:un_dep -Encoding ascii
                    $Script:notFound.ForEach({[PSCustomObject]$_}) | Select-Object Sno,Name |ConvertTo-Csv -NoTypeInformation|Out-File -Append -FilePath $Script:un_dep
                }
            }
            foreach ($data in $Script:notFound){
                $Script:allInfoArr += $data
            }
        }else{
            foreach ($data in $Script:unavail){
                $Script:allInfoArr += $data
            }
            if (!($Script:unavail.Count -eq "0")) {
                if ($Script:output_type -eq 1){

    echo "Artifacts unobtained from Enterprise, FOSS, Maven Central and LOB repo :"|Out-File -Append -FilePath $Script:un_dep -Width 4000
                    $Script:unavail.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name -AutoSize |Out-File -Append -FilePath $Script:un_dep -Width 4000
                }else{
                    echo "Artifacts unobtained from Enterprise FOSS Maven Central and LOB repo :"|Out-File -Append -FilePath $Script:un_dep -Encoding ascii
                    $Script:unavail.ForEach({[PSCustomObject]$_}) | Select-Object Sno,Name |ConvertTo-Csv -NoTypeInformation|Out-File -Append -FilePath $Script:un_dep
                }
            }    
        }
    }
    #if ($Script:output_type -eq 1){
     #   $Script:allInfoArr.ForEach({[PSCustomObject]$_}) | sort-Object Sno | Format-Table Sno,Name,URL -AutoSize |Out-Null
    #}else{
     #   $Script:allInfoArr.ForEach({[PSCustomObject]$_}) | sort-Object Sno | Select-Object Sno,Name,URL|ConvertTo-Csv -NoTypeInformation |Out-Null
    #}


    #if (!($Script:unavail.Count -eq "0")) {
        
     #   if ($Script:output_type -eq 1){
        
      #  $Script:myarr.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name,NearestMatch -AutoSize |Out-File -Append -FilePath $av_dep -Width 4000
      #  }else{
        
      #  $Script:myarr.ForEach({[PSCustomObject]$_}) | Select-Object Sno,Name,NearestMatch|ConvertTo-Csv -NoTypeInformation |Out-File -Append -FilePath $av_dep
      #  }
       
    #}
    if ($Script:output_type -eq 1){
        if ($1_5_option -eq 1) {
            $Script:allInfoArr.ForEach({[PSCustomObject]$_}) |Sort-Object Sno |Format-Table Sno,Name,SHA1,GAV,URL -AutoSize |Out-File -Append -FilePath $Script:all_info -Width 10000
         } else {
                $Script:allInfoArr.ForEach({[PSCustomObject]$_}) |Sort-Object Sno |Format-Table Sno,Name,SHA1,URL -AutoSize |Out-File -Append -FilePath $Script:all_info -Width 10000        
            }
    }else{

_______________________________________________

_______________________________________________________

_________________________________________________

 if ($1_5_option -eq 1) {
            $Script:allInfoArr.ForEach({[PSCustomObject]$_}) |Sort-Object Sno |Select-Object Sno,Name,SHA1,GAV,URL|ConvertTo-Csv -NoTypeInformation|Out-File -Append -FilePath $Script:all_info -Encoding ascii
         } else {
                $Script:allInfoArr.ForEach({[PSCustomObject]$_}) |Sort-Object Sno |Select-Object Sno,Name,SHA1,URL|ConvertTo-Csv -NoTypeInformation| Out-File -Append -FilePath $Script:all_info -Encoding ascii        
            } 
    }
    $Script:notFound = @()
    if ($1_5_option -eq "2") {
        echo "Searching for alternate artifacts by JAR attributes:"
        if (!($Script:unavail.Count -eq "0")) {

  echo "***********************************************"|Out-File -Append -FilePath $Script:un_dep -Width 4000
            echo "Alternate artifacts searched by JAR attributes:"|Out-File -Append -FilePath $Script:un_dep -Width 4000
            echo "***********************************************"|Out-File -Append -FilePath $Script:un_dep -Width 4000
        }
        foreach ($alt in $Script:unavail){
            $dest=$alt.Name.Replace(".jar","")
            
            try{
                Unzip $alt.Path $temp\$dest
                $atr_title=Get-Content $temp\$dest\META-INF\MANIFEST.MF | Where-Object { $_ -match 'Implementation-Title' }
                $atr_version=Get-Content $temp\$dest\META-INF\MANIFEST.MF | Where-Object { $_ -match 'Implementation-Version' }
            }
            catch [Exception]{
                $atr_title = $null
                $atr_version = $null
            }

 if (!( $atr_title.Length -eq "0" -or $atr_version.Length -eq "0")) {
                $var = $alt.Name
                if($Script:flag_etp -eq 1){
                search_artifactory_alternate $alt $global:apikey_etp $Script:etp_art_url $atr_title.ToLower().Split(": ")[2] $atr_version.Split(": ")[2] "Enterprise Artifactory"
                }
                if($Script:flag_foss -eq 1){
                search_artifactory_alternate $alt $global:apikey_foss $Script:foss_art_url $atr_title.ToLower().Split(": ")[2] $atr_version.Split(": ")[2] "Fossware Artifactory"
                }
                $url="http://search.maven.org/solrsearch/select?q=a:"+$atr_title.ToLower().Split(": ")[2]+"+AND+v:"+$atr_version.Split(": ")[2]+"&rows=20&wt=json"
                $result=(new-object net.webclient).DownloadString($url)
                $json=$result|ConvertFrom-Json
                    if (!($json.response.numFound -eq "0")) {
                        $mydata = @{}
                   

 $mydata.Sno= $alt.Sno
                        $mydata.Name = $alt.Name       
                        $mydata.SHA1 = $alt.SHA1
                        $mydata.GAV = $alt.GAV
                        $mydata.FoundIn = "Maven Central"
                        $mydata.URL = "http://search.maven.org/#search|gav|1|a:"+$atr_title.ToLower().Split(": ")[2]+"%20AND%20v:"+$atr_version.Split(": ")[2]
                        $Script:altArr += $mydata
                      }
                         
            } else { $Script:notFound += $alt }
                if ($Script:notFoundAtr.Count -eq "2") {
                    $Script:notFound += $alt
                }
        $Script:notFoundAtr = @()
                if (!($Script:altArr.Count -eq "0")) {
                    echo "Alternate artifacts by attributes for $var" | Out-File  -Append -FilePath $Script:un_dep -Width 4000

 if ($Script:output_type -eq 1){
                    $Script:altArr.ForEach({[PSCustomObject]$_}) | Format-Table Sno,Name,FoundIn,URL -AutoSize |Out-File -Append -FilePath $Script:un_dep -Width 4000
                    }else{
                    $Script:altArr.ForEach({[PSCustomObject]$_}) |Select-Object Sno,Name,FoundIn,URL|ConvertTo-Csv -NoTypeInformation |Out-File -Append -FilePath $Script:un_dep
                    }
                }
        $Script:altArr = @()
        }
    
        $Script:unavail = @()
        $Script:unavail = $Script:notFound
    }
    
    echo "Searching for alternate artifacts by artifactId:"
   
    alternateSearch $Script:unavail $Script:un_dep
}

############# Gradle dependency file creation #############
function createGradleDependencies {
    $Script:obtainedJarsArray = @()
    getInputs
    extractBuildDependencies
    if (!($Script:jarArray.Count -eq 0)){
    accessCheck $Script:etp_art_url
    $Script:flag_etp = $Script:flag
    searchLocalRepoDependencies
    
    if($Script:notFound.Count -eq 0) {
        $Script:pathArray = @()
        createGradleDependencyFile
    }else{
        echo "`n"
        echo "Found unobtained artifacts. Please verify the repo name and upload all dependencies to artifactory to create gradle dependencies file."
        #echo "`n"
        #echo "Output files are stored at location :"$Script:outputDir
    }
  }
}

function createGradleDependencyFile {
    echo "`n"
    echo "Creating gradle dependency file..."
    [string]$gradle_file = "$Script:outputDir\artifactoryDependencies.txt"
    try{ Remove-Item $gradle_file } catch [Exception] {}
    #"dependencies {" | Out-File -Append -FilePath $gradle_file -Width 4000
    "" | Out-File -Append -FilePath $gradle_file -Width 4000
    if($Script:3_option -eq 1) {
        $Script:myarr = @()
        $Script:myarr = $Script:obtainedJarsArray
    }
    #Add obtained dependencies to gradle file
    if($Script:myarr.Count -gt 0) {       
        foreach($artifact in $Script:myarr) {

  $configStart = "compile ("
            $configEnd = ")"
            $configMid = ""
    
            $version = $artifact.Version
            $artifactId = $artifact.ArtifactId
            $groupId = $artifact.GroupId
            $configMid = $configMid + "group:" + "'" + $groupId + "', "
            $configMid = $configMid + "name:" + "'" + $artifactId + "', "
            $configMid = $configMid + "version:" + "'" + $version + "'"
            $configStart + $configMid + $configEnd | Out-File -Append -FilePath $gradle_file -Width 4000
        }
    }
    #Add uploaded dependencies to gradle file
    if($Script:pathArray.Count -gt 0) {
        foreach($path in $Script:pathArray) {

 $configStart = "compile ("
            $configEnd = ")"
            $configMid = ""
            $version = $path.Version
            $artifactId = $path.ArtifactId 
            $groupId = $path.GroupId
            $configMid = $configMid + "group:" + "'" + $groupId + "', "
            $configMid = $configMid + "name:" + "'" + $artifactId + "', "
            $configMid = $configMid + "version:" + "'" + $version + "'"
            $configStart + $configMid + $configEnd | Out-File -Append -FilePath $gradle_file -Width 4000
        }
    }

  "" | Out-File -Append -FilePath $gradle_file -Width 4000
   # "}" | Out-File -Append -FilePath $gradle_file -Width 4000
    echo "`n"
    echo "Created gradle dependency file"
}
############# Config creation #############
function createConfigFile {
    
    echo "`n"
    echo "Creating Config file..."
    $config_file = "$Script:outputDir\artifactoryRepo.properties"
    try{ Remove-Item $config_file } catch [Exception] {}
    $artifactory_repokey = "artifactory_repokey = "
    $artifactory_url = "artifactory_url = "
    $repos = $Script:searchRepos.Split(",")
    for ($i=0; $i -lt $repos.Count; $i++) {

 [string]$artifactory_url = $artifactory_url + $Script:etp_art_url + "/" + $repos[$i].Trim() + ", "
        [string]$artifactory_repokey = $artifactory_repokey + $repos[$i].Trim() + ", "
    }
    $artifactory_url = $artifactory_url.TrimEnd(", ")
    $artifactory_repokey = $artifactory_repokey.TrimEnd(", ")
    $artifactory_repokey | Out-File -Append -FilePath $config_file -Width 4000
    $artifactory_url | Out-File -Append -FilePath $config_file -Width 4000
    echo "`n"
    echo "Created Config file"
    echo "`n"
    echo "Output files are stored at location :"$Script:outputDir
}
function transitiveDependencyTree {
    
    getInputs
    $hdrEnt = @{ "X-JFrog-Art-Api" = "$global:apikey_etp" }

$result=Invoke-RestMethod -Method GET -Uri "http://artifactory.wellsfargo.com/artifactory/api/storage/local-clt-ars-maven-remdiate" -Headers $hdrEnt
    
    if(!($result.children.uri.Contains("/Dependency_data.html")) -or
        !($result.children.uri.Contains("/apache-ant-1.10.1.zip")) -or
        !($result.children.uri.Contains("/apache-maven-3.3.9.zip")) -or
        !($result.children.uri.Contains("/build.xml")) -or
        !($result.children.uri.Contains("/ivysettings.xml")) -or
        !($result.children.uri.Contains("/viz.js")))
    {
        echo "`nCould not find few/all of the dependent files necessary for generating dependency graph in Artifactory."
    } else{
    
    if (!(Test-Path $PSScriptRoot\software\viz-js)){mkdir $PSScriptRoot\software\viz-js|Out-Null}

if (!(Test-Path $PSScriptRoot\software\viz-js\viz.js)){
    #mkdir $PSScriptRoot\software\viz-js
        try{
            Invoke-RestMethod -Method GET -Uri $Script:etp_art_url\local-clt-ars-maven-remdiate\viz.js -Headers $hdrEnt -OutFile "$PSScriptRoot\software\viz-js\viz.js"
        }
        catch [Exception]{
            
        }
    }
    if (!(Test-Path $Script:outputDir\Dependency_data.html)){
    #mkdir $PSScriptRoot\software\viz-js
        try{
            Invoke-RestMethod -Method GET -Uri $Script:etp_art_url\local-clt-ars-maven-remdiate\Dependency_data.html -Headers $hdrEnt -OutFile "$Script:outputDir\Dependency_data.html"
        }
        catch [Exception]{
        }
    }

if($Script:4_option -eq 1 -or $Script:4_option -eq 2){
        
        if (!(Test-Path $PSScriptRoot\software\maven)){mkdir $PSScriptRoot\software\maven|Out-Null}
        if (!(Test-Path $PSScriptRoot\software\maven\apache-maven-3.3.9)){
        #mkdir $PSScriptRoot\software\maven
        Invoke-RestMethod -Method GET -Uri $Script:etp_art_url\local-clt-ars-maven-remdiate\apache-maven-3.3.9.zip -Headers $hdrEnt -OutFile "$PSScriptRoot\software\maven\apache-maven-3.3.9.zip"
        Unzip "$PSScriptRoot\software\maven\apache-maven-3.3.9.zip" "$PSScriptRoot\software\maven\"
        }
        if (!(Test-Path $env:M2_HOME)){
        echo Setting M2_HOME
        $env:M2_HOME="$PSScriptRoot\software\maven\apache-maven-3.3.9"
        }
 $settingsFile=Get-Content "$PSScriptRoot\software\maven\apache-maven-3.3.9\conf\settings.xml"
        $settingsFile.Replace("api_key",$global:apikey_etp).Replace("user_repo",$Script:virtualRepo)|Set-Content $outputDir\user_settings.xml -force
        if($Script:4_option -eq 1){
        echo "`n"
        echo "Generating the pom.xml file"
        mvn -q -gs $outputDir\user_settings.xml dependency:get -Dartifact="$Script:groupId":"$Script:artifactId":"$Script:version":pom -Ddest="$outputDir\pom.xml"
        echo "`n"
        echo "Generating the transitive dependency tree"
        mvn -q -gs $outputDir\user_settings.xml dependency:tree -Dverbose -f $outputDir\pom.xml -DoutputType=txt -DoutputFile="$outputDir\tree.txt"
        
        echo "`n"
        echo "Generating the data for the dependency Graph"
        mvn -q -gs $outputDir\user_settings.xml dependency:tree -f $outputDir\pom.xml -DoutputType=dot -DoutputFile="$outputDir\data.gv"
        }

 if($Script:4_option -eq 2){
        
        echo "`n"
        echo "Generating the transitive dependency tree"
        mvn -q -gs $outputDir\user_settings.xml dependency:tree -Dverbose -f $Script:buildFilePath -DoutputType=txt -DoutputFile="$outputDir\tree.txt"
        echo "`n"
        echo "Generating the data for the dependency Graph"
        mvn -q -gs $outputDir\user_settings.xml dependency:tree -f $Script:buildFilePath -DoutputType=dot -DoutputFile="$outputDir\data.gv"
        }
        $dotFile=Get-Content $outputDir\data.gv
        echo "inputData =" | Out-File -Append $outputDir\inputData.gv
    
        for($i = 0; $i -lt $dotFile.Count-1; $i++) {
            "'"+$dotFile[$i]+" '+" |Out-File -Append $outputDir\inputData.gv
            if ($i -eq 0){

 echo "'    ratio = auto; '+ " |Out-File -Append $outputDir\inputData.gv
                echo "'    graph [size = `"30,10`"]; '+  " |Out-File -Append $outputDir\inputData.gv
                echo "'    node [style=filled, fontsize=10]; '+  " |Out-File -Append $outputDir\inputData.gv
                "' "+$dotFile[0].Split("")[1]+" [color=`"0.408 0.498 1.000`"]" +"'+" |Out-File -Append $outputDir\inputData.gv
            }
        }
        echo "' }  ';"|Out-File -Append $outputDir\inputData.gv
        start iexplore.exe $outputDir\Dependency_data.html
    }
    if($Script:4_option -eq 3){
        if (!(Test-Path $PSScriptRoot\software\ivy)){mkdir $PSScriptRoot\software\ivy|Out-Null}
        if (!(Test-Path $PSScriptRoot\software\ivy\apache-ant-1.10.1)){
        #mkdir $PSScriptRoot\software\ivy

 Invoke-RestMethod -Method GET -Uri $Script:etp_art_url\local-clt-ars-maven-remdiate\apache-ant-1.10.1.zip -Headers $hdrEnt -OutFile "$PSScriptRoot\software\ivy\apache-ant-1.10.1.zip"
        Unzip "$PSScriptRoot\software\ivy\apache-ant-1.10.1.zip" "$PSScriptRoot\software\ivy\"
        }
        if (!(Test-Path $outputDir\build.xml)){
        #mkdir $PSScriptRoot\software\viz-js
        Invoke-RestMethod -Method GET -Uri $Script:etp_art_url\local-clt-ars-maven-remdiate\build.xml -Headers $hdrEnt -OutFile "$outputDir\build.xml"
        }
        if (!(Test-Path $outputDir\ivysettings.xml)){
        #mkdir $PSScriptRoot\software\viz-js
        Invoke-RestMethod -Method GET -Uri $Script:etp_art_url\local-clt-ars-maven-remdiate\ivysettings.xml -Headers $hdrEnt -OutFile "$outputDir\ivysettings.xml"
        }

$settingsFile=Get-Content "$outputDir\ivysettings.xml"
        $settingsFile.Replace("uid",$Script:uid).Replace("password",$Script:password).Replace("user_repo",$Script:virtualRepo)|Set-Content $PSScriptRoot\software\ivy\apache-ant-1.10.1\lib\ivy\org\apache\ivy\core\settings\ivysettings.xml -force
        
        cd $PSScriptRoot\software\ivy\apache-ant-1.10.1\lib\ivy
        jar cf ivy.jar *
        mv ivy.jar ..\
        #if (!(Test-Path $env:ANT_HOME)){
        #echo "Setting ANT_HOME"
        $env:ANT_HOME="$PSScriptRoot\software\ivy\apache-ant-1.10.1"
        #}
        cp $Script:buildFilePath $outputDir\ivy.xml
        cd $outputDir
        echo "`n"

 echo "Generating the transitive dependency tree"
        ant dependency-tree -l $outputDir\dependency-tree.txt|Out-Null
        
        $tree=Select-String -Path dependency-tree.txt -Pattern 'dependencytree'
        for($i = 0; $i -lt $tree.Count; $i++) {
        $tree[$i].Line.Split("]")[1]| Out-File -Append tree.txt
        }
        echo "`n"
        echo "Generating the data for the dependency Graph"
        ant -q generate-dot
        echo "inputData =" | Out-File -Append $outputDir\inputData.gv
        echo "' digraph dependency_graph { '+" | Out-File -Append $outputDir\inputData.gv
        echo "'    ratio = auto; '+ " |Out-File -Append $outputDir\inputData.gv
        echo "'    graph [size = `"40,40`"]; '+  " |Out-File -Append $outputDir\inputData.gv
        echo "'    node [style=filled, fontsize=10]; '+  " |Out-File -Append $outputDir\inputData.gv

  $dot=Select-String -Path build\*dot -Pattern ";"
        
        for($i = 0; $i -lt $dot.Count; $i++) {
        "'"+$dot[$i].Line+" '+"|Out-File -Append $outputDir\inputData.gv
        }
        echo "' }  ';"|Out-File -Append $outputDir\inputData.gv
        start iexplore.exe $outputDir\Dependency_data.html
        Remove-Item -Path $PSScriptRoot\software\ivy\apache-ant-1.10.1\lib\ivy.jar
        Remove-Item -Path $PSScriptRoot\software\ivy\apache-ant-1.10.1\lib\ivy\org\apache\ivy\core\settings\ivysettings.xml
        #Remove-Item -Path $PSScriptRoot\software\ivy\apache-ant-1.10.1\lib\ivy\ivy.jar
    }
    }
}
############# Script start #############
checkJavaHome
main_menu
if ($Script:main_option -eq 4) {
    exit
}

if ($Script:main_option -eq 3) {
    transitiveDependencyTree
}
if (!($Script:main_option -match $Script:valid_MainMenu) ) {
    echo "Invalid selection. Please select from the given options"
    $Script:main_option=read-host "Select"
}
if($Script:main_option -eq 1) {
    if($Script:1_option -match $Script:valid_1_buildFileMenu) {
        extractBuildDependencies
        searchBuildDependencies
    }
    
    if($Script:1_option -eq 4) {
        dependenciesFromLocalRepo
    }
    if($Script:1_option -eq 5) {
        dependenciesFromLocalRepo
    }
} 
if($Script:main_option -eq 2) {
    uploadDependencies
}
Invoke-Expression $MyInvocation.InvocationName
