# == Define: access_permissions
#
# This resource configures the access ACLs for DCOM-apps
#
# === Parameters
#
# [*app_access_permissions*]
#   A nested hash including all necessary params for the application
#
# [*app_access_permissions['appID']*]
#   The predefined application ID
#   Should look like this: {00020906-0000-0000-C000-000000000046}
#
# [*app_access_permissions['ensure']*]
#   Defines wether the user / group should exist or not
#
# [*app_access_permissions['users']*]
#   List(array) of users / groups that should be managed
#
# [*app_access_permissions['acl']*]
#   Defines wether the permission level should be granted or denied
#
# [*app_access_permissions['level']*]
#   Defines the permission level
#   l - local access
#   r - remote access
#
define dcom::access_permissions (
  Hash $app_access_permissions = undef,
) {

  if ! defined(Class['dcom']) {
    fail('You must include the dcom base class before using any dcom defined resources')
  }

  if $app_access_permissions =~ Stdlib::Compat::Hash {

    $app_access_permissions.each |String $key, Hash $value| {

      if $value['acl'] == 'permit' {
        $acl_set = 'permitted'
        $acl_unset = 'denied'
      } elsif $value['acl'] == 'deny' {
        $acl_set = 'denied'
        $acl_unset = 'permitted'
      } else {
        fail('The parameter "$app_access_permissions[\'acl\']" must be either "permit" or "deny"')
      }

      # lint:ignore:140chars
      if $value['users'] =~ Stdlib::Compat::Array {

        $value['users'].each |Integer $index, String $user| {

          case $value['ensure'] {
            'present','true': {
              case $value['level'] {
                'r': {
                  exec { "Reset local permissions for \'${user}\' in application \'${key}\'":
                    path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                    command  => "&${facts['temp_path']}\\DComPermEx.exe -aa \"${value['appID']}\" remove \"${user}\"",
                    unless   => "\$list=(&${facts['temp_path']}\\DComPermEx.exe -aa \"${value['appID']}\" list | Out-String).Split(\"`r`n\",[StringSplitOptions]::RemoveEmptyEntries);
                                if (!((Write-Output \$list | ForEach-Object {\$_.Contains(\"Local\") -and \$_.Contains(\"${user}\")}) -eq \$true)) {exit 0} else {exit 1}",
                    provider => 'powershell',
                  }

                  exec { "Set access permissions for \'${user}\' in application \'${key}\'":
                    path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                    command  => "&${facts['temp_path']}\\DComPermEx.exe -aa \"${value['appID']}\" set \"${user}\" ${value['acl']} level:${value['level']}",
                    unless   => "\$list=(&${facts['temp_path']}\\DComPermEx.exe -aa \"${value['appID']}\" list | Out-String).Split(\"`r`n\",[StringSplitOptions]::RemoveEmptyEntries);
                                if ((Write-Output \$list | ForEach-Object {\$_.Contains(\"Remote\") -and \$_.Contains(\"${user}\") -and \$_.Contains(\"${acl_set}\")}) -eq \$true) {exit 0} else {exit 1}",
                    provider => 'powershell',
                  }
                }
                'l': {
                  exec { "Reset remote permissions for \'${user}\' in application \'${key}\'":
                    path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                    command  => "&${facts['temp_path']}\\DComPermEx.exe -aa \"${value['appID']}\" remove \"${user}\"",
                    unless   => "\$list=(&${facts['temp_path']}\\DComPermEx.exe -aa \"${value['appID']}\" list | Out-String).Split(\"`r`n\",[StringSplitOptions]::RemoveEmptyEntries);
                                if (!((Write-Output \$list | ForEach-Object {\$_.Contains(\"Remote\") -and \$_.Contains(\"${user}\")}) -eq \$true)) {exit 0} else {exit 1}",
                    provider => 'powershell',
                  }

                  exec { "Set access permissions for \'${user}\' in application \'${key}\'":
                    path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                    command  => "&${facts['temp_path']}\\DComPermEx.exe -aa \"${value['appID']}\" set \"${user}\" ${value['acl']} level:${value['level']}",
                    unless   => "\$list=(&${facts['temp_path']}\\DComPermEx.exe -aa \"${value['appID']}\" list | Out-String).Split(\"`r`n\",[StringSplitOptions]::RemoveEmptyEntries);
                                if ((Write-Output \$list | ForEach-Object {\$_.Contains(\"Local\") -and \$_.Contains(\"${user}\") -and \$_.Contains(\"${acl_set}\")}) -eq \$true) {exit 0} else {exit 1}",
                    provider => 'powershell',
                  }
                }
                # To make sure, that the ACL can be switched between 'permit' & 'deny' the first Exec has to remove the User
                # if the opposite ACL permission will still be found in the unless check.
                # For some reason - when using level:"l,r" - DCOM keeps the "permitted" and "denied" entries in it´s database and that kills the "unless" check
                # not an issue when setting only level:r or level:l though
                /(l,r|r,l)/: {
                  exec { "Remove ${acl_unset} remote or local permissions for \'${user}\' in application \'${key}\'":
                    path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                    command  => "&${facts['temp_path']}\\DComPermEx.exe -aa \"${value['appID']}\" remove \"${user}\"",
                    unless   => "\$list=(&${facts['temp_path']}\\DComPermEx.exe -aa \"${value['appID']}\" list | Out-String).Split(\"`r`n\",[StringSplitOptions]::RemoveEmptyEntries);
                                if (!((Write-Output \$list | ForEach-Object {\$_.Contains(\"Remote\") -and \$_.Contains(\"Local\") -and \$_.Contains(\"${user}\") -and \$_.Contains(\"${acl_unset}\")}) -eq \$true)) {exit 0} else {exit 1}",
                    provider => 'powershell',
                  }

                  exec { "Set access permissions for \'${user}\' in application \'${key}\'":
                    path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                    command  => "&${facts['temp_path']}\\DComPermEx.exe -aa \"${value['appID']}\" set \"${user}\" ${value['acl']} level:${value['level']}",
                    unless   => "\$list=(&${facts['temp_path']}\\DComPermEx.exe -aa \"${value['appID']}\" list | Out-String).Split(\"`r`n\",[StringSplitOptions]::RemoveEmptyEntries);
                                if ((Write-Output \$list | ForEach-Object {\$_.Contains(\"Remote\") -and \$_.Contains(\"Local\") -and \$_.Contains(\"${user}\") -and \$_.Contains(\"${acl_set}\")}) -eq \$true) {exit 0} else {exit 1}",
                    provider => 'powershell',
                  }
                }
                default: {
                  fail("The given level \"${value['level']}\" is not supported. Make sure it is one of the following formats: ([l,r],[l],[r])")
                }
              }
            }
            'absent','false': {
              exec { "Remove access permissions for \'${user}\' in application \'${key}\'":
                path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
                command  => "&${facts['temp_path']}\\DComPermEx.exe -aa \"${value['appID']}\" remove \"${user}\"",
                unless   => "if (!(&${facts['temp_path']}\\DComPermEx.exe -aa \"${value['appID']}\" list | Out-String).Contains(\"${user}\")) {exit 0} else {exit 1}",
                provider => 'powershell',
              }
            }
            default: {
              fail('The parameter $app_access_permissions[\'ensure\'] only accepts the following values: \'present\', \'absent\', \'true\' or \'false\'!')
            }
          }
        }
      } else {
        fail('The parameter "$app_access_permissions[\'users\']" must be an array!')
      }
    } # lint:endignore
  } else {
    fail('The parameter "$app_access_permissions" must be a hash!')
  }
}
