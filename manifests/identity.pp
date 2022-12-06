# == Define: identity
#
# This define configures the user for an application
#
# === Parameters
#
# [*app_identities*]
#   A nested hash including all necessary params for the application
#
# [*app_identities['appID']*]
#   The predefined application ID
#   Should look like this: {00020906-0000-0000-C000-000000000046}
#
# [*app_identities['identity_type']*]
#   Depending on the identity_type the defined resource will handle the correct execution
#
# [*app_identities['user']*]
#   Sets the launching user for the application
#   Only necessary for identity_type = custom user
#
# [*app_identities['password']*]
#   Password of the chosen user. Must be in clear-text
#   Only necessary for identity_type = custom user
#
define dcom::identity (
  Hash $app_identities = undef,
) {

  if ! defined(Class['dcom']) {
    fail('You must include the dcom base class before using any dcom defined resources')
  }

  # lint:ignore:140chars
  if $app_identities =~ Stdlib::Compat::Hash {
    #notice("app_identities is a Hash")
    $app_identities.each |String $key, Hash $value| {

      exec { "Enabling DCOM configuration to set up identities for application '${key}'":
        path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
        command  => "New-PSDrive -PSProvider Registry -Name HKCR -Root HKEY_CLASSES_ROOT -ErrorAction SilentlyContinue;
                     New-Item -Path \"HKCR:\\AppID\\${value['appID']}\" -Value \"${key}\";",
        unless   => "New-PSDrive -PSProvider Registry -Name HKCR -Root HKEY_CLASSES_ROOT -ErrorAction SilentlyContinue;
                     if (Test-Path \"HKCR:\\AppID\\${value['appID']}\") {exit 0} else {exit 1}",
        provider => 'powershell',
      }

      case $value['identity_type'] {
        /^(c|C)ustom (u|U)ser$/: {
          if ($value['user'] == undef) {
            fail('The parameter "$user" is not set!')
          } elsif ($value['password'] == undef) {
            fail('The parameter "$password" is not set!')
          }

          exec { "Set User-Login '${value['user']}' for application '${key}'":
            path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
            command  => "\$result = &\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -runas \"${value['appID']}\" \"${value['user']}\" \"${value['password']}\";
                        if (\$result.Length -gt 0) {throw \$result} else {exit 0}",
            unless   => "if ((Get-ItemProperty -Path \"HKLM:\\SOFTWARE\\Classes\\AppID\\${value['appID']}\" | Select-Object -ExpandProperty \"RunAs\" -ErrorAction SilentlyContinue) -Contains \"${value['user']}\") {exit 0} else {exit 1}",
            provider => 'powershell',
          }
        }
        /^(i|I)nteractive (u|U)ser$/: {
          exec { "Set User-Login 'Interactive User' for application '${key}'":
            path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
            command  => "\$result = &\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -runas \"${value['appID']}\" \"Interactive User\";
                        if (\$result.Length -gt 0) {throw \$result} else {exit 0}",
            unless   => "if ((Get-ItemProperty -Path \"HKLM:\\SOFTWARE\\Classes\\AppID\\${value['appID']}\" | Select-Object -ExpandProperty \"RunAs\" -ErrorAction SilentlyContinue) -Eq \"Interactive User\") {exit 0} else {exit 1}",
            provider => 'powershell',
          }
        }
        /^(l|L)aunching (u|U)ser$/: {
          exec { "Set User-Login 'Launching User' for application '${key}'":
            path     => 'C:\Windows\System32\WindowsPowerShell\v1.0',
            command  => "\$result = &\"C:\\Program Files\\DComPermEx\\DComPermEx.exe\" -runas \"${value['appID']}\" \"Launching User\";
                        if (\$result.Length -gt 0) {throw \$result} else {exit 0}",
            unless   => "if ([string]::IsNullOrEmpty((Get-ItemProperty -Path \"HKLM:\\SOFTWARE\\Classes\\AppID\\${value['appID']}\" | Select-Object -ExpandProperty \"RunAs\" -ErrorAction SilentlyContinue))) {exit 0} else {exit 1}",
            provider => 'powershell',
          }
        }
        default: {
          fail("The given identity type \"${value['identity_type']}\" is not supported or written incorrectly!")
        }
      }
    } # lint:endignore
  } else {
    fail('The parameter "$app_identities" must be a hash!')
  }
}
