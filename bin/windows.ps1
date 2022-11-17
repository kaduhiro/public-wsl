# run by administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrators")) { Start-Process powershell.exe "-File `"$PSCommandPath`" $args" -Verb RunAs; exit }

# execution policy "Restricted" to "Unrestricted"
Set-ExecutionPolicy Unrestricted

[bool] $script:enable = $true

[string] $script:dist
[string] $script:wsl_address
[int] $script:ssh_port = 22
[string] $script:firewall_name = 'Public WSL'

function motd() {
    switch ($enable) {
        $true {
            $option = "enable"
        }
        $false {
            $option = "disable"
        }
    }

    echo @"

  :'########::'##::::'##:'########::'##:::::::'####::'######:::::'##:::::'##::'######::'##:::::::
  : ##.... ##: ##:::: ##: ##.... ##: ##:::::::. ##::'##... ##:::: ##:'##: ##:'##... ##: ##:::::::
  : ##:::: ##: ##:::: ##: ##:::: ##: ##:::::::: ##:: ##:::..::::: ##: ##: ##: ##:::..:: ##:::::::
  : ########:: ##:::: ##: ########:: ##:::::::: ##:: ##:::::::::: ##: ##: ##:. ######:: ##:::::::
  : ##.....::: ##:::: ##: ##.... ##: ##:::::::: ##:: ##:::::::::: ##: ##: ##::..... ##: ##:::::::
  : ##:::::::: ##:::: ##: ##:::: ##: ##:::::::: ##:: ##::: ##:::: ##: ##: ##:'##::: ##: ##:::::::
  : ##::::::::. #######:: ########:: ########:'####:. ######:::::. ###. ###::. ######:: ########:
  :..::::::::::.......:::........:::........::....:::......:::::::...::...::::......:::........::

  Distribution        : $dist
  WSL IP Address      : $wsl_address
  SSH Port            : $ssh_port
  Allow Ping          : $option
  SSH Port Forwarding : $option
  Through Firewall    : $option

"@
}

function init() {
    $dists = (wsl -l -q) -ne ""

    $tChoiceDescription = "System.Management.Automation.Host.ChoiceDescription"

    $options = @()
    for ($i = 0; $i -lt $dists.count; $i++) {
        $options += New-Object $tChoiceDescription ($dists[$i] + " (&$i)")
    }
    $options += New-Object $tChoiceDescription "Quit (&Q)"

    $number = $host.ui.PromptForChoice($null, "? Select Distribution", $options, 0)

    $script:dist = $dists[$number] -replace "`0", ""
    if ($dist -eq "") {
        Exit 0
    }

    $script:wsl_address = (wsl -d "$dist" -e /bin/sh -c "hostname -I | cut -d' ' -f1").Trim()
}

function ping() {
    switch ($enable) {
        $true {
            Get-NetFirewallRule -Name FPS-ICMP4-ERQ-In | Set-NetFirewallRule -enabled true
        }
        $false {
            Get-NetFirewallRule -Name FPS-ICMP4-ERQ-In | Set-NetFirewallRule -enabled false
        }
    }

    Get-NetFirewallRule -name  FPS-ICMP4-ERQ-In-NoScope
}

function ssh() {
    switch ($enable) {
        $true {
            netsh interface portproxy delete v4tov4 listenport=$ssh_port
            netsh interface portproxy add v4tov4 listenport=$ssh_port connectaddress=$wsl_address
        }
        $false {
            netsh interface portproxy delete v4tov4 listenport=$ssh_port
        }
    }

    netsh interface portproxy show v4tov4 Outbound -LocalPort 22 -Action Allow -Protocol TCP
}

function firewall() {
    switch ($enable) {
        $true {
            New-NetFirewallRule -DisplayName "$firewall_name" -Direction Outbound -LocalPort $ssh_port -Action Allow -Protocol TCP
            New-NetFirewallRule -DisplayName "$firewall_name" -Direction Inbound -LocalPort $ssh_port -Action Allow -Protocol TCP
        }
        $false {
            Remove-NetFireWallRule -DisplayName "$firewall_name"
        }
    }
}

function bootstrap() {
    $wsl_dir = $PSScriptRoot.Replace('\', '/') 
    $drive = $wsl_dir -replace '^(.).+$', '$1'
    $wsl_dir = $wsl_dir.Replace($drive + ':', ('/mnt/' + $drive.ToLower())) 

    wsl -d "$dist" -e /bin/sh ($wsl_dir + '/wsl.sh')
}

# main
function main() {
    switch -Regex ($script:args[0]) {
        '^(enable|true|yes|y)$' {
            $script:enable = $true
        }
        '^(disable|false|no|n)$' {
            $script:enable = $false
        }
    }

    init
    motd

    $yn = Read-Host "? Run on $dist [y/N] "
    if ($yn -eq 'y') {
        ping
        ssh
        firewall

        $yn = Read-Host "? Set a bootstrap in WSL [y/N] "
        if ($yn -eq 'y') {
            bootstrap
        }
    }

    Pause
}

main
