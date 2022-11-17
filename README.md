# Public WSL

## Feature

* Allow ping to host
* Forwarding ssh connections to WSL
* Allow firewalls to pass through
* Set startup commands in WSL
  * `service ssh start`
  * `service docker start` (option)

## Requirement

* Windows 10+
* WSL2
  * Ubuntu

## Usage

1. Download ZIP

    https://github.com/kaduhiro/public-wsl/archive/master.zip

2. Unarchive and open `bin` directory in that

3. Running `windows.ps1` in PowerShell

    > default is `enable`, and to `disable`, pass `disable` `false` `no` `n` as an argument

    ```
    .\windows.ps1 disable
    ```
