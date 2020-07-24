# Overview 
This is a simple script to handle some WiFi connection related functionality
from the command line.  It relies on wpa_supplicant, dhclient, unbound and other
utilities like `ip` and `iwlist` generally found in Ubuntu and other GNU/Linux
distributions.

This is largely meant for my personal use and isn't thoroughly tested or
prepared for any one else to plug and play.

## Build/Installation
The binary relies on an .ini file in the root of the directory 

`nimble build` to build the source

## TODO
- restart DHCP to flush out leases after disconnect
- clear out any routes on the device after disconnect
- check interface status before enabling/disabling
