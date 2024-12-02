gci /mnt/c/dev/podman-bgd-serve/quadlet | 
    %{ systemctl stop $_.Name.Replace(".container","") } 
