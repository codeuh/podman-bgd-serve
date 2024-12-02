$ErrorActionPreference = "Stop"

# params
$projectName = ""
$buildName = "flask-app-1"
$registry = "localhost:8082"
$targetTag = "latest"

# functions
function Get-SuffixSwapper {
    param (
      [string]$Suffix
    )
  
    switch ($Suffix) {
      '-blue' { return '-green' }
      '-green' { return '-blue' }
      default { Write-Error "Unknown suffix: $Suffix"; return '' }
    }
  }

# mainline
$activeContainer = podman container list -f "name=$($buildName)" --format json | ConvertFrom-Json

if (!$activeContainer) {
    Write-Error "Error: Couldn't find a running container who's name begins with $buildName"
}

if ($activeContainer.Length -ne 1) {
    Write-Warning "$($activeContainer |ConvertTo-Json -depth 20)"
    Write-Error "Error: Found more than one container who's name begins with $buildName. I only expect one running container with a suffix of -blue, or -green. See above warning for containers details."
}

$activeContainerName = $activeContainer.Names
Write-Host "Active container: $($activeContainerName)"
$activePort = $activeContainer.Ports.host_port
Write-Host "Active port: $activePort"
$lastDashIndex = $activeContainerName.LastIndexOf("-")
$containerBaseName = $activeContainerName.Substring(0, $lastDashIndex)
$activeContainerSuffix = $activeContainerName.Substring($lastDashIndex)
$activeContainerTag = $activeContainerSuffix.Replace("-", "")
$inactiveContainerSuffix = Get-SuffixSwapper $activeContainerSuffix
$inactiveContainerTag = $inactiveContainerSuffix.Replace("-", "")
$targetContainerName = "$($containerBaseName)$($inactiveContainerSuffix)"
Write-Host "Inactive container: $($targetContainerName)"

$inactivePublishPortMapping = Get-Content "/etc/containers/systemd/$($targetContainerName).container" `
    | Select-String "PublishPort"

if (!$inactivePublishPortMapping) {
    Write-Error "Error: Couldn't find a publish port mapping in the inactive containers ($($targetContainerName)) quadlet file."
}

if ($inactivePublishPortMapping.Length -ne 1) {
    Write-Error "Error: Found more than one publish port mapping in the inactive containers ($($targetContainerName)) quadlet file."
}

# the line below will take an input from $inactivePublishPortMapping that looks like:
#   PublishPort=5001:5000
# and assigns 5001, the host port, to $targetPort
$targetPort = (($inactivePublishPortMapping -split "=")[1] -split ":")[0]
Write-Host "Inactive port: $($targetPort)"

Write-Host "Starting $activeContainerTag to $inactiveContainerTag swap..."

Write-Host "Pulling targetTag $targetTag..."
podman image pull "$($registry)/$($buildName):$($targetTag)"

Write-Host "Tagging targetTag $targetTag with inactiveContainerTag $inactiveContainerTag"
podman tag "$($registry)/$($buildName):$($targetTag)" "$($registry)/$($buildName):$($inactiveContainerTag)"

Write-Host "Starting $targetContainerName systemd service..."
systemctl unmask $targetContainerName
systemctl start $targetContainerName

Write-Host "Running update_nginx.sh..."
podman exec nginx-serve bash /tools/update_nginx.sh $activePort $targetPort

Write-Host "Stopping $activeContainerName"
systemctl stop $activeContainerName
systemctl mask $activeContainerName