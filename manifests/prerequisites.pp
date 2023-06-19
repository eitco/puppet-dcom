# == Class: dcom::prerequisites
class dcom::prerequisites () {
  file { 'Creating Folder for DComPermEx.exe':
    ensure => 'directory',
    path   => 'C:/Program Files/DComPermEx',
  }

  file { 'Copying DComPermEx.exe':
    ensure => 'file',
    mode   => '0777',
    source => 'puppet:///modules/dcom/DComPermEx.exe',
    path   => 'C:/Program Files/DComPermEx/DComPermEx.exe',
  }
}
