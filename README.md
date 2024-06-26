# Command Line Interface reference implementation for Boomi CI/CD

The CLI utility wraps calls to [Boomi Atomsphere APIs](https://help.boomi.com/bundle/integration/page/r-atm-AtomSphere_API_6730e8e4-b2db-4e94-a653-82ae1d05c78e.html). Handles input and output JSON files and performance orchestration for deploying and managing Boomi runtimes.
  
## Pre-requistes
  - The CLI utility currently runs on any Unix OS and invokes BASH shell scripts
  - On Windows this has been tested with [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
  - Boomi Atomsphere API token to be generated [link](https://help.boomi.com/bundle/integration/page/int-AtomSphere_API_Tokens_page.html)
  - The CLI utility requires jq - JSON Query interpreter installed 
  - The CLI requires xmllit interpreter 
  
        ## Using yum 
        $ yum install -y jq 
        $ yum install -y libxml2
        
        ## Using apt
        $ apt-get install -y jq 
        $ apt-get install libxml2-utils

## Set up
Clone the scripts folder on to a Unix Machine. The scripts folder contains the following directories. 

    $ git clone https://github.com/OfficialBoomi/boomiinstall-cli.git
    $ cd boomiinstall-cli/cli/scripts


- **bin** has the bash scripts for CLI
- **conf** has configuration files for Molecule installation 
- **json** has json templates used in the Atomsphere API calls.

- Check this link to create the authToken [link](https://help.boomi.com/bundle/integration/page/int-AtomSphere_API_Tokens_page.html)

        $ # Set the following variables before the scripts are invoked. 
        $ Or Update in the bin/exports.sh and run source bin/exports
        $ source bin/exports.sh 
        
        $ # Get values from user or parameter store
        $ # The following credentials can be stored in parameter store and retrieved dynamically
        $ # Example to retrieve form an AWS store "$(aws ssm get-parameter --region xx --with-decryption --output text --query Parameter.Value --name /Parameter.name)
        
        $ SCRIPTS_HOME='/pathto/scripts'
        $ cd $SCRIPTS_HOME
        $ export accountId=company_account_uuid
        $ export authToken=BOOMI_TOKEN.username@company.com:aP1k3y02-mob1-b00M-M0b1-at0msph3r3aa        
        $ export h1="Content-Type: application/json"
        $ export h2="Accept: application/json"
        $ export baseURL=https://api.boomi.com/api/rest/v1/$accountId
        $ export WORKSPACE=$(pwd)
               
      
        $ export VERBOSE="false" # Bash verbose output; set to true only for testing.
        $ export SLEEP_TIMER=0.2 # Delays curl request to the platform to set the rate under 5 requests/second

        

        
## Run your first script

        $ source bin/exports.sh
        $ source bin/installerToken.sh > index.html
    
## List of Interfaces

The followings script/ calls a single API. Arguments in *italics* are optional

| **SCRIPT_NAME** | **ARGUMENTS** | **JSON FILE** |**API/Action**| **Notes**|
| ------ | ------ | ------ | ------ | ------ |
|createAtom.sh|atomName, cloudId|createAtom.json|Atom/create|Create Cloud Atom in $cloudId|
|createAtomAttachment.sh|atomId, envId|createAtomAttachment.json|EnvironmentAtomAttachment /create|Attach Atom to Environment|
|createEnvironment.sh|env, classification|createEnvironment.json|Environment/create|Create Env (only if does not exist)|
|createEnvironmentRole.sh|roleName, env|createEnvironmentRole.json|EnvironmentRole /create|Attach a Role to an Env|
|init.sh|atomType, atomName, classification, env|-|Installs Boomi atom and molecule, creates environment|
|installerToken.sh|atomType, *cloudId*|installerToken.json|InstallerToken|Gets an installer token atomType must be one-of **ATOM**, **MOLECULE** or **CLOUD**. If |queryAtom.sh|atomName, atomType, atomStatus|queryAtom.json|Atom/query|Queries Atom use atomType and atomStatus =* for wild card|
|queryAtomAttachment.sh|atomId, envId|queryAtomAttachment.json|EnvironmentAtomAttachment /query|Queries an Atom/Env Attachment|
|queryEnvironment.sh|env, classification|queryEnvironment.json|Environment/query|Queries an Env in an Account. Use classification=* for wildcard.|
|queryRole.sh|roleName|queryRole.json|Role/query|Queries a role exists|
|updateAtom.sh|atomId, purgeHistoryDays|updateAtom.json|Atom/$atomId/update|Update atom properties (purgeHistory)|
|updateSharedServer.sh|atomName, overrideUrl, apiType, auth, url|updateSharedServer.json|SharedServerInformation /$atomId /update|Updates Shared Web Server URL and APIType|




## common. sh
The CLI framework is built around the functions in the common.sh
| **Function** | **Usage**|
| ------ | ------ |
|callAPI| Invokes the AtomSphere API and captures the output in out.json|
|call_script| This is used in the dynamicScript* jobs and interprets the configuration files to invoke CLI scripts dynamically|
|getAPI| Invokes the GET request on AtomSphere API and captures the output in out.json|
|getXMLAPI| Invokes the GET/XML request on AtomSphere API and captures the output in out.xml|
|clean| unsets input variables, retains output variables|
|createJSON| Creates the input JSON from the template JSON and ARGUMENTS in a tmp.json |
|extract| Exports specific variables in the envirnoment variable from out.json|
|extractMap| Exports specific array in the envirnoment variable from out.json |
|inputs|Parses the inputs and validates its against the mandatory ARGUMENTS |
|printReportHead| Prints report header. Called by the Publish report scripts|
|printReportRow|  Prints row data. Called by the Publish report scripts|
|printReportTail|  Prints report tail. Called by the Publish report scripts|
|usage| Prints the script usage details|
|getValueFrom| Used in the updateExtensions.sh to lookup secret values, this function needs to be changed for special usecases|

## Troubleshooting and help
- If a script fails to run, it will print the ERROR_MESSAGE and exit with an ERROR_CODE i.e. $? > 0
- Check the $WORKSPACE/tmp.json for the input.json
- Check the $WORKSPACE/out.json for the out.json
- Call the API manually using
- set the export VERBOSE="true" to see DEBUG messages
 curl -s -X POST -u $authToken -H "${h1}" -H "${h2}" $URL -d@"${WORKSPACE}"/tmp.json > "${WORKSPACE}"/out.json
 
