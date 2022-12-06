# == Define: app_activation_launch_permissions
#
# This resource configures the launch and activation ACLs for DCOM-apps
#
# === Parameters
#
# [*app_activation_launch_permissions*]
#   A nested hash including all necessary params for the chosen application
#
# [*app_activation_launch_permissions['appID']*]
#   The predefined application ID
#   Should look like this: {00020906-0000-0000-C000-000000000046}
#
# [*app_activation_launch_permissions['ensure']*]
#   Defines wether the user / group should exist or not
#
# [*app_activation_launch_permissions['users']*]
#   List(array) of users / groups that should be managed
#
# [*app_activation_launch_permissions['acl']*]
#   Defines wether the permission level should be granted or denied
#
# [*app_activation_launch_permissions['level']*]
#   Defines the permission level
#   l   - local activation & launch
#   r   - remote activation & launch
#   l,r - local & remote activation & launch
#   ll  - local launch
#   la  - local activation
#   rl  - remote launch
#   ra  - remote activation
#
define dcom::activation_launch_permissions (
  Hash $app_activation_launch_permissions = undef,
) {

  if ! defined(Class['dcom']) {
    fail('You must include the dcom base class before using any dcom defined resources')
  }

  if $app_activation_launch_permissions =~ Stdlib::Compat::Hash {
    #notice("app_activation_launch_permissions is a Hash")
    $app_activation_launch_permissions.each |String $key, Hash $value| {

      if $value['acl'] == 'permit' {
        $acl_set = 'permitted'
        $acl_unset = 'denied'
      } elsif $value['acl'] == 'deny' {
        $acl_set = 'denied'
        $acl_unset = 'permitted'
      } else {
        fail('The parameter "$app_activation_launch_permissions[\'acl\']" must be either "permit" or "deny"')
      }

      exec { "Enabling DCOM configuration to set up activation & access permissions for application '${key}'":
        path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
        command  => "New-PSDrive -PSProvider Registry -Name HKCR -Root HKEY_CLASSES_ROOT -ErrorAction SilentlyContinue;
                     New-Item -Path \"HKCR:\\AppID\\${value['appID']}\" -Value \"${key}\";",
        unless   => "New-PSDrive -PSProvider Registry -Name HKCR -Root HKEY_CLASSES_ROOT -ErrorAction SilentlyContinue;
                     if (Test-Path \"HKCR:\\AppID\\${value['appID']}\") {exit 0} else {exit 1}",
        provider => 'powershell',
      }

      # lint:ignore:140chars
      if $value['users'] =~ Stdlib::Compat::Array {

        $value['users'].each |Integer $index, String $user| {
          case $value['ensure'] {
            'present','true': {
              case $value['level'] {
                'l': {
                  exec { "Reset remote launch & activation permissions for '${user}' in application '${key}'":
                    path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                    command  => "\$result = &\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" remove \"${user}\";
                                if ((\$result -like \"*Successfully*\").Count -gt 0) {exit 0} else {throw \$result}",
                    unless   => "\$list=(&\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" list | Out-String).Split(\"`r`n\",[StringSplitOptions]::RemoveEmptyEntries);
                                if (!((Write-Output \$list | ForEach-Object {\$_.Contains(\"Remote\") -and \$_.Contains(\"${user}\")}) -eq \$true)) {exit 0} else {exit 1}",
                    provider => 'powershell',
                  }

                  exec { "Set local launch & activation permissions for '${user}' in application '${key}'":
                    path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                    command  => "\$result = &\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" set \"${user}\" ${value['acl']} level:${value['level']};
                                 if ((\$result -like \"*Successfully*\").Count -gt 0) {exit 0} else {throw \$result}",
                    unless   => "\$list=(&\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" list | Out-String).Split(\"`r`n\",[StringSplitOptions]::RemoveEmptyEntries);
                                if ((Write-Output \$list | ForEach-Object {(\$_.Contains(\"Local\") -and \$_.Contains(\"launch\")) -or (\$_.Contains(\"Local\") -and \$_.Contains(\"activation\")) -and \$_.Contains(\"${user}\") -and \$_.Contains(\"${acl_set}\")}) -eq \$true) {exit 0} else {exit 1}",
                    provider => 'powershell',
                  }
                }
                'r': {
                  exec { "Reset local launch & activation permissions for '${user}' in application '${key}'":
                    path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                    command  => "\$result = &\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" remove \"${user}\";
                                if ((\$result -like \"*Successfully*\").Count -gt 0) {exit 0} else {throw \$result}",
                    unless   => "\$list=(&\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" list | Out-String).Split(\"`r`n\",[StringSplitOptions]::RemoveEmptyEntries);
                                if (!((Write-Output \$list | ForEach-Object {\$_.Contains(\"Local\") -and \$_.Contains(\"${user}\")}) -eq \$true)) {exit 0} else {exit 1}",
                    provider => 'powershell',
                  }

                  exec { "Set remote launch & activation permissions for '${user}' in application '${key}'":
                    path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                    command  => "\$result = &\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" set \"${user}\" ${value['acl']} level:${value['level']};
                                if ((\$result -like \"*Successfully*\").Count -gt 0) {exit 0} else {throw \$result}",
                    unless   => "\$list=(&\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" list | Out-String).Split(\"`r`n\",[StringSplitOptions]::RemoveEmptyEntries);
                                if ((Write-Output \$list | ForEach-Object {(\$_.Contains(\"Remote\") -and \$_.Contains(\"launch\")) -or (\$_.Contains(\"Remote\") -and \$_.Contains(\"activation\")) -and \$_.Contains(\"${user}\") -and \$_.Contains(\"${acl_set}\")}) -eq \$true) {exit 0} else {exit 1}",
                    provider => 'powershell',
                  }
                }
                /(l,r|r,l)/: {
                  exec { "Reset ${acl_unset} remote or local launch & activation permissions for '${user}' in application '${key}'":
                    path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                    command  => "\$result = &\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" remove \"${user}\";
                                if ((\$result -like \"*Successfully*\").Count -gt 0) {exit 0} else {throw \$result}",
                    unless   => "\$list=(&\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" list | Out-String).Split(\"`r`n\",[StringSplitOptions]::RemoveEmptyEntries);
                                if (!((Write-Output \$list | ForEach-Object {(\$_.Contains(\"Remote\") -or \$_.Contains(\"Local\")) -and \$_.Contains(\"${user}\") -and \$_.Contains(\"${acl_unset}\")}) -eq \$true)) {exit 0} else {exit 1}",
                    provider => 'powershell',
                  }

                  exec { "Set remote launch & activation permissions for '${user}' in application '${key}'":
                    path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                    command  => "\$result = &\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" set \"${user}\" ${value['acl']} level:${value['level']};
                                if ((\$result -like \"*Successfully*\").Count -gt 0) {exit 0} else {throw \$result}",
                    unless   => "\$list=(&\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" list | Out-String).Split(\"`r`n\",[StringSplitOptions]::RemoveEmptyEntries);
                                if ((Write-Output \$list | ForEach-Object {\$_.Contains(\"Remote\") -and \$_.Contains(\"Local\") -and (\$_.Contains(\"launch\") -or \$_.Contains(\"activation\")) -and \$_.Contains(\"${user}\") -and \$_.Contains(\"${acl_set}\")}) -eq \$true) {exit 0} else {exit 1}",
                    provider => 'powershell',
                  }
                }
                'la': {
                  exec { "Reset all launch & activation permissions for '${user}' in application '${key}'":
                    path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                    command  => "\$result = &\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" remove \"${user}\";
                                if ((\$result -like \"*Successfully*\").Count -gt 0) {exit 0} else {throw \$result}",
                    unless   => "\$list=(&\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" list | Out-String).Split(\"`r`n\",[StringSplitOptions]::RemoveEmptyEntries);
                                if (!((Write-Output \$list | ForEach-Object {\$_.Contains(\"Remote\") -or (\$_.Contains(\"Local\") -and \$_.Contains(\"launch\")) -and \$_.Contains(\"${user}\")}) -eq \$true)) {exit 0} else {exit 1}",
                    provider => 'powershell',
                  }

                  exec { "Set local activation permissions for '${user}' in application '${key}'":
                    path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                    command  => "\$result = &\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" set \"${user}\" ${value['acl']} level:${value['level']};
                                if ((\$result -like \"*Successfully*\").Count -gt 0) {exit 0} else {throw \$result}",
                    unless   => "\$list=(&\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" list | Out-String).Split(\"`r`n\",[StringSplitOptions]::RemoveEmptyEntries);
                                if ((Write-Output \$list | ForEach-Object {\$_.Contains(\"Local\") -and \$_.Contains(\"activation\") -and \$_.Contains(\"${user}\") -and \$_.Contains(\"${acl_set}\")}) -eq \$true) {exit 0} else {exit 1}",
                    provider => 'powershell',
                  }
                }
                'll': {
                  exec { "Reset all launch & activation permissions for '${user}' in application '${key}'":
                    path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                    command  => "\$result = &\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" remove \"${user}\";
                                if ((\$result -like \"*Successfully*\").Count -gt 0) {exit 0} else {throw \$result}",
                    unless   => "\$list=(&\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" list | Out-String).Split(\"`r`n\",[StringSplitOptions]::RemoveEmptyEntries);
                                if (!((Write-Output \$list | ForEach-Object {\$_.Contains(\"Remote\") -or (\$_.Contains(\"Local\") -and \$_.Contains(\"activation\")) -and \$_.Contains(\"${user}\")}) -eq \$true)) {exit 0} else {exit 1}",
                    provider => 'powershell',
                  }

                  exec { "Set local launch permissions for '${user}' in application '${key}'":
                    path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                    command  => "\$result = &\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" set \"${user}\" ${value['acl']} level:${value['level']};
                                if ((\$result -like \"*Successfully*\").Count -gt 0) {exit 0} else {throw \$result}",
                    unless   => "\$list=(&\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" list | Out-String).Split(\"`r`n\",[StringSplitOptions]::RemoveEmptyEntries);
                                if ((Write-Output \$list | ForEach-Object {\$_.Contains(\"Local\") -and \$_.Contains(\"launch\") -and \$_.Contains(\"${user}\") -and \$_.Contains(\"${acl_set}\")}) -eq \$true) {exit 0} else {exit 1}",
                    provider => 'powershell',
                  }
                }
                'ra': {
                  exec { "Reset all launch & activation permissions for '${user}' in application '${key}'":
                    path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                    command  => "\$result = &\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" remove \"${user}\";
                                if ((\$result -like \"*Successfully*\").Count -gt 0) {exit 0} else {throw \$result}",
                    unless   => "\$list=(&\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" list | Out-String).Split(\"`r`n\",[StringSplitOptions]::RemoveEmptyEntries);
                                if (!((Write-Output \$list | ForEach-Object {\$_.Contains(\"Local\") -or (\$_.Contains(\"Remote\") -and \$_.Contains(\"launch\")) -and \$_.Contains(\"${user}\")}) -eq \$true)) {exit 0} else {exit 1}",
                    provider => 'powershell',
                  }

                  exec { "Set remote activation permissions for '${user}' in application '${key}'":
                    path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                    command  => "\$result = &\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" set \"${user}\" ${value['acl']} level:${value['level']};
                                if ((\$result -like \"*Successfully*\").Count -gt 0) {exit 0} else {throw \$result}",
                    unless   => "\$list=(&\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" list | Out-String).Split(\"`r`n\",[StringSplitOptions]::RemoveEmptyEntries);
                                if ((Write-Output \$list | ForEach-Object {\$_.Contains(\"Remote\") -and \$_.Contains(\"activation\") -and \$_.Contains(\"${user}\") -and \$_.Contains(\"${acl_set}\")}) -eq \$true) {exit 0} else {exit 1}",
                    provider => 'powershell',
                  }
                }
                'rl': {
                  exec { "Reset all launch & activation permissions for '${user}' in application '${key}'":
                    path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                    command  => "\$result = &\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" remove \"${user}\";
                                if ((\$result -like \"*Successfully*\").Count -gt 0) {exit 0} else {throw \$result}",
                    unless   => "\$list=(&\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" list | Out-String).Split(\"`r`n\",[StringSplitOptions]::RemoveEmptyEntries);
                                if (!((Write-Output \$list | ForEach-Object {\$_.Contains(\"Local\") -or (\$_.Contains(\"Remote\") -and \$_.Contains(\"activation\")) -and \$_.Contains(\"${user}\")}) -eq \$true)) {exit 0} else {exit 1}",
                    provider => 'powershell',
                  }

                  exec { "Set remote activation permissions for '${user}' in application '${key}'":
                    path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                    command  => "\$result = &\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" set \"${user}\" ${value['acl']} level:${value['level']};
                                if ((\$result -like \"*Successfully*\").Count -gt 0) {exit 0} else {throw \$result}",
                    unless   => "\$list=(&\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" list | Out-String).Split(\"`r`n\",[StringSplitOptions]::RemoveEmptyEntries);
                                if ((Write-Output \$list | ForEach-Object {\$_.Contains(\"Remote\") -and \$_.Contains(\"launch\") -and \$_.Contains(\"${user}\") -and \$_.Contains(\"${acl_set}\")}) -eq \$true) {exit 0} else {exit 1}",
                    provider => 'powershell',
                  }
                }
                default: {
                  fail("The given level '${value['level']}' is not supported. Make sure it is one of the following formats: ([l,r],[l],[r],[la],[ll],[ra],[rl])")
                }
              }
            }
            'absent','false': {
              exec { "Remove launch or activation permissions for '${user}' in application '${key}'":
                path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                command  => "\$result = &\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" remove \"${user}\";
                            if ((\$result -like \"*Successfully*\").Count -gt 0) {exit 0} else {throw \$result}",
                unless   => "if (!(&\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -al \"${value['appID']}\" list | Out-String).Contains(\"${user}\")) {exit 0} else {exit 1}",
                provider => 'powershell',
              }
            }
            default: {
              fail('The parameter "$app_activation_launch_permissions[\'ensure\']" only accepts the following values: "present", "absent", "true" or "false"!')
            }
          }
        }
      } else {
        fail('The parameter "$app_activation_launch_permissions[\'users\']" must be an array!')
      }
    } # lint:endignore
  } else {
    fail('The parameter "$app_activation_launch_permissions" must be a hash!')
  }
}
