# dcom

## Table of Contents

1. [Description](#description)
1. [Setup](#setup)
1. [Usage](#usage)
    * [Identity](#identity)
    * [Access permissions](#access-permissions)
    * [Launch and activation permissions](#launch-and-activation-permissions)
1. [Reference](#reference)
    * [Parameters](#parameters)
    * [Classes](#classes)
    * [Defined resources](#defined-resources)
    * [Facts](#facts)
1. [Limitations](#limitations)
1. [Final thoughts](#final-thoughts)

## Description

This module manages the user / group assignments in the DCOM configuration for Windows apps.
Changing those DCOM settings usually means to do it by hand, complex self-written scripts...or by using this module!

It can help you out with the following things: manage the user identity of the app it should be launched as, manage the user access permissions, manage the local / remote launch & activation permissions.

In order to do that the dcom module uses an extended version of a tool called "DComPerm" whose soure code can be found in the Windows SDK.
The extended version can be found here: https://github.com/albertony/dcompermex


## Setup

In order to use it you need to include the main class first, which will then ensure that the DComPerm.exe will be copied into the TEMP-folder of the system.
```ruby
include dcom
```

Then - depending on what you need - just call the defined resources from your module like that:
```ruby
dcom::identity{ 'Setting up identities':
    app_identities => $app_identities,
}

# or

dcom::activation_launch_permissions{ 'Setting up activation & launch permissions':
    app_activation_launch_permissions => $app_activation_launch_permissions,
}

# or

dcom::access_permissions{ 'Setting up access permissions':
    app_access_permissions => $app_access_permissions,
}
```


## Usage

The configuration depends on hiera.
To set up the applications the way you want them, you need to know the App-ID of the application.
Each program has it´s own App-ID which will be always the same in every installation.
You can either find it out by going through the DCOM-config manually (*dcomcnfg.exe*) or with the help of PowerShell.
Here are some examples. 
```powershell
Get-WMIObject Win32_DCOMApplicationSetting -Filter 'Caption like "%Microsoft Word%"'

Get-WMIObject Win32_DCOMApplicationSetting -Filter 'Description like "%Microsoft Excel%"'
```
*Get-WMIObject* will then create a WQL query out of it and return the result. The %-sign is a wildcard (like *).

Every defined resource is expecting the parameter to be of the datatype Hash. The resources are designed to manage one or more applications or users / groups.
The keys inside the hash are predefined and mandatory.

### Identity

There are three categories of identities in DCOM for regular apps: launching user, interactive user & custom user.
In the following example we configure the Word application to be launched in the context of the user *"domain_user"*.
```ruby
your_module::app_identities:
  'Word 2013':
    appID: '{00020906-0000-0000-C000-000000000046}'
    identity_type: 'custom user'
    user: 'CONTOSO\domain_user'
    password: 'password'
```
The user & password keys are only needed for the *"custom user"* identity type.

Now let´s add a few more apps with a different identity configuration.
```ruby
your_module::app_identities:
  'Word 2013':
    appID: '{00020906-0000-0000-C000-000000000046}'
    identity_type: 'custom user'
    user: 'CONTOSO\domain_user'
    password: 'password'
  'Outlook 2013':
    appID: '{0006F03A-0000-0000-C000-000000000046}'
    identity_type: 'custom user'
    user: 'local_user'
    password: 'password'
  'Excel 2013':
    appID: '{00020812-0000-0000-C000-000000000046}'
    identity_type: 'launching user'
  'Powerpoint 2013':
    appID: '{91493441-5A91-11CF-8700-00AA0060263B}'
    identity_type: 'interactive user'
```
Done!

### Access permissions
The access permissions are configured in a similar way, just with a few more keys. On top of that you can also set the configuration for one or more users. Let´s see an example:
```ruby
your_module::app_access_permissions:
  'Word 2013':
    appID: '{00020906-0000-0000-C000-000000000046}'
    ensure: 'present'
    users: 
      - 'CONTOSO\user1'
    acl: 'permit'
    level: 'l,r'
  'Excel 2013':
    appID: '{00020812-0000-0000-C000-000000000046}'
    ensure: 'present'
    users: 
      - 'CONTOSO\user1'
      - 'CONTOSO\user2'
    acl: 'deny'
    level: 'r'
  'PowerPoint 2013':
    appID: '{91493441-5A91-11CF-8700-00AA0060263B}'
    ensure: 'present'
    users:
      - 'CONTOSO\user2'
      - 'local_user3'
    acl: 'permit'
    level: 'l'
```

What if it is not a user but a local group that you want to add? Or maybe even a domain group?
```ruby
your_module::app_access_permissions:
  'Word 2013':
    appID: '{00020906-0000-0000-C000-000000000046}'
    ensure: 'present'
    users: 
      - 'Administrators' # local group
      - 'CONTOSO\Admin-Group' # domain group
    acl: 'permit'
    level: 'l,r'
```

### Launch and activation permissions
The launch & activation permissions are configured the same way as the access permissions. 
```ruby
your_module::app_activation_launch_permissions:
  'Word 2013':
    appID: '{00020906-0000-0000-C000-000000000046}'
    ensure: 'present'
    users:
      - 'CONTOSO\user1'
    acl: 'permit'
    level: 'la'
  'Excel 2013':
    appID: '{00020812-0000-0000-C000-000000000046}'
    ensure: 'present'
    users:
      - 'CONTOSO\user2'
      - 'local_user3'
    acl: 'deny'
    level: 'l,r'
  'PowerPoint 2013':
    appID: '{91493441-5A91-11CF-8700-00AA0060263B}'
    ensure: 'present'
    users:
      - 'local_user3'
    acl: 'permit'
    level: 'ra'
```

Now let´s assume you want to have two users configured for the same app but with different permissions.
Unfortunately I haven´t found a better way yet...but here is a workaround how it can be done:
```ruby
your_module::app_activation_launch_permissions:
  'Word 2013 - user1':
    appID: '{00020906-0000-0000-C000-000000000046}'
    ensure: 'present'
    users:
      - 'CONTOSO\user1'
    acl: 'permit'
    level: 'la'
  'Word 2013 - user2':
    appID: '{00020906-0000-0000-C000-000000000046}'
    ensure: 'present'
    users:
      - 'CONTOSO\user2'
    acl: 'permit'
    level: 'l,r'
```

If an application is configured with
```ruby
ensure: 'absent'
```
then all the users configured in the *users* key will be removed from the DCOM configuration for that application!

## Reference

### Parameters
```ruby
Hash app_identities:
        'key':    
            Pattern['^{[A-Z0-9].*-[A-Z0-9].*-[A-Z0-9].*-[A-Z0-9].*-[A-Z0-9].*}$'] appID
            String[Enum['custom user','interactive user','launching user']] identity_type
            Optional[String] user
            Optional[String] password

Hash app_access_permissions:
        'key':    
            Pattern['^{[A-Z0-9].*-[A-Z0-9].*-[A-Z0-9].*-[A-Z0-9].*-[A-Z0-9].*}$'] appID
            String[Enum['present','absent']] ensure
            Array[String] users
            String[Enum['permit','deny']] acl
            String[Enum['l','r','l,r']] level

Hash app_activation_launch_permissions:
        'key':    
            Pattern['^{[A-Z0-9].*-[A-Z0-9].*-[A-Z0-9].*-[A-Z0-9].*-[A-Z0-9].*}$'] appID
            String[Enum['present','absent']] ensure
            Array[String] users
            String[Enum['permit','deny']] acl
            String[Enum['l','r','l,r','la','ll','ra','rr']] level

Default: undef
```

### Classes
```ruby
# main class
Class['dcom']

# ensures that the DComPerm.exe is present within the TEMP-path
Class['dcom::prerequisites']
```

### Defined resources
```ruby
# manages the launch identity of an app
dcom::identity

# manages the access permissions for an app
dcom::access_permissions

# manages the activation and launch permissions for an app
dcom::activation_launch_permissions
```

### Facts
```ruby
# custom fact to determine the TEMP-path of the current user since the default puppet facts do not cover that
$facts['temp_path']
```

## Limitations

* Predefined (default) user / groups can´t be changed
* a user / group can be added through this module, the removal however won´t happen automatically when removing them from the nested hash
    * workaround #1: create new hash element with the user / group marked as 'ensure: absent'
    * workaround #2: remove the user / group from DCOM-config by hand
* This module is limited by the features that the DComPerm-tool offers
* This module has been only tested on Windows Server 2012 R2 so far, DComPerm requires at least Vista / Server 2008
* This module has been only tested on Puppet 5 so far - newer versions will be tested in the future

## Final thoughts

Although the feature set is mostly complete (based on what can be done with DComPerm) there might be still some room for improvement.
If you have some feedback or something isn´t working correctly - feel free to write me: rhelwig@eitco.de
