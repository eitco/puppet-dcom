# == Class: dcom
#
# This module manages the user / group assignments in the DCOM configuration for Windows apps.
#
# === Authors
#
# * Roman Helwig <mailto:rhelwig@eitco.de>
#
class dcom () {
  if $facts['kernel'] != 'windows' {
    fail('This module runs only on Windows OS!')
  }

  contain dcom::prerequisites
}
