gci /mnt/c/dev/podman-bgd-serve/quadlet | 
    %{ systemctl start $_.Name.Replace(".container","") } 