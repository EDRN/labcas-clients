# LabCAS Donwload
# ===============
#
# This is a Windows PowerShell script that uses the LabCAS API to download
# data from LabCAS.
#
# To use this script, you'll need three things:
#
# - Your EDRN username
# - The password for that username
# - A file calles "files.csv" that contains a list of file URLs to download.
#
# The "files.csv" is normally downloaded (along with this script)
# automatically from https://edrn-labcas.jpl.nasa.gov/ when you attempt to
# download data larger than 953.7 MiB in size or 100 or more individual
# files.
#
# Copyright 2023 California Institute of Technology. ALL RIGHTS
# RESERVED. U.S. Government Sponsorship acknowledged.
# 
#
# Get up username and password
# ----------------------------

$labcas_username = Read-Host -Prompt "EDRN username"
$secure_password = Read-Host -Prompt "EDRN password" -AsSecureString
$plain_password = [System.Net.NetworkCredential]::new("", $secure_password).Password
$pair = "${labcas_username}:${plain_password}"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$basicAuth = "Basic $base64"
$headers = @{ Authorization = $basicAuth }

# Set up networking
# -----------------

add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem
        ) {
            return true;
        }
    }
"@
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# Import and loop over the CSV
# ----------------------------

Import-Csv -Path files.csv -Header 'key','value' | ForEach-Object {
    $key = $_.key
    $value = $_.value
    Write-Output "Downloading $key to $value"
    $response = Invoke-WebRequest -Uri $key -Headers $headers -Outfile $value
}
