# Changelog

All notable changes to this project will be documented in this file.

## Release 0.3.3

* Updating library dependencies & Puppet 8 preparation

## Release 0.3.2

* Added a way for the module to determine wether the app is listed in the DCOM config already or not and adding it to the list in case it isn´t
* Added error handling: if DComPermEx couldn´t realize the settings an error will be raised (the exception of DComPermEx is only visible when running in debug-mode though)
* Updated the README documentation
* Included License of DComPermEx-Tool (since i forgot it in the previous release - credit where credit is due!)
* Change: instead of using a temporary path DComPermEx.exe will be copied under 'C:\Program Files\DComPermEx' from now on

## Release 0.2.2

* Minor changes in README documentation

## Release 0.2.0

* The initial release