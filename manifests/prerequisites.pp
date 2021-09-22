# == Class: dcom::prerequisites
class dcom::prerequisites () {

  file{'Ensure Temp Path is present':
    ensure => 'directory',
    path   => $facts['temp_path']
  }

  file{'Ensure DComPermEx.exe is present':
    ensure => 'file',
    mode   => '0777',
    source => 'puppet:///modules/dcom/DComPermEx.exe',
    path   => "${facts['temp_path']}/DComPermEx.exe",
  }
}
