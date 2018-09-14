# Lotteries.DVS.AzureScripts

## Summary

This repo contains the set of IAC deployment scripts to automate deployment of Azure environments for the DVS:

- [Draw automation program of work](https://confluence.tattsgroup.io/wiki/display/LT/Draw+Automation+Program+of+Work)
- [Azure Pilot of DVS for Draw Automation](https://confluence.tattsgroup.io/wiki/display/CTO/Azure+Pilot+-+DVS+Draw+Automation)

## Prerequisites

- Azure account access to run these deployments (talk to the CTO team for Azure permissions)
- AzureRM powershell modules: https://docs.microsoft.com/en-us/powershell/azure/install-azurerm-ps
  - `Install-Module AzureRM`
  - `Import-Module AzureRM`

## Deployment

### Determinstic builds

Deterministic builds can be performed using the standard Microsoft Visual Studio Community Azure VM.

- Create the VM by running the `deploy.ps1` script in the `\determinstic-builds\` folder.
- Copy the source zip and scripts from `\deterministic-builds\build` directory to the Azure VM into a new directory `c:\build`
  - The source zip can be obtained by clicking the zip link under the release tag in github
  - The scripts are configured to output artifacts to `c:\build`
- Run the start.ps1 script and fill in the details as prompted

After completion of the above a transcript of the build process will be recorded along with a hash of all the release binaries and a zip of the binaries.

The above artifacts can now be copied off the VM and the VM itself can be destroyed using the `teardown.ps1` script.

### VMs only

Navigate to the environment folder you wish to deploy for

- To deploy the VMs run the script named `deploy_XXXX_vms.ps1`
- To destroy the VMs run the script named `teardown_vms_XXXX.ps1`

### Full Stack

Navigate to the environment folder you wish to deploy for

- To deploy the VMs run the script named `deploy_XXXX.ps1`
- To destroy the VMs run the script named `teardown_vms_XXXX.ps1` and `teardown_paas_XXXX.ps1`

### Starting VMs (only necessary if VMs are turned off)

To start up offline VMs, run the `start_vms_XXXX.ps1` powershell script under the environment heading.
