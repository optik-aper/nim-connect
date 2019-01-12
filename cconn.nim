import osproc, streams, strutils, os, nre, rdstdin, posix

const WPA_SUPP_PATH = "/etc/wpa_supplicant"
const WPA_SUPP_LOG = "/var/log/wpa_supplicant.log"
const INTERFACE = "wlp2s0"

proc checkArgs(): bool =
  if paramCount() < 2:
    return false
  return true

proc scanSSIDs(): seq[string] =

  var ssids = newSeq[string]() 
  var l = ""
  let ps = startProcess("/sbin/iwlist", "", [INTERFACE, "scan"])
  let s = outputStream(ps)

  let match = re"ESSID"

  while s.readLine(l.TaintedString):
    if contains(l, re"ESSID"): 
      add(ssids, split(split(l, re":")[1], {'"'})[1])

  return ssids

proc checkConf(ssid: string): bool =
  return existsFile(WPA_SUPP_PATH & "/" & ssid & ".conf")

proc createConf(ssid: string, pass: string): bool = 
  let conf_file = WPA_SUPP_PATH & "/" & ssid & ".conf"

  let (outp, exit) = execCmdEx(
    "wpa_passphrase " & ssid & " " & pass & " > " & conf_file 
  )

  if exit > 0:
    echo("Could not create conf file")
    return false

  return true

proc wpaConnect(ssid: string): bool=
  let cmd = "wpa_supplicant -i " & INTERFACE & 
    " -f " & WPA_SUPP_LOG & 
    " -c " & WPA_SUPP_PATH & "/" & ssid & ".conf" 

  let ps = startProcess(
    command = cmd, 
    options = {poEvalCommand,poDemon}
  )

  if not running(ps):
    echo("Can not start wpa_supplicant daemon")
    return false

  return true

proc connect(ssid: string): bool=

  if not checkConf(ssid):
    let pass = readLineFromStdin "Password: "
    if not createConf(ssid, pass):
      echo("Connection failed in conf file creation")
      return false

  if not wpaConnect(ssid):
    echo("Connection failed when trying wpa_supplicant")
    return false

  return true

proc configureDHCP(): bool =
  let ps = startProcess(
    command = "dhclient " & INTERFACE,
    options = {poEvalCommand,poDemon}
  )

  if not running(ps):
    echo("Can not start dhclient daemon")
    return false

  return true

proc restartDNS(): bool = 
  var (u_out, u_exit) = execCmdEx("service unbound restart")

  if u_exit > 0:
    echo("Could not restart unbound")
    return false

  var (n_out, n_exit) = execCmdEx("service nscd restart")

  if n_exit > 0:
    echo("Could not restart nscd")
    return false

  return true

proc main(): void =

  if not checkArgs():
    discard
    # TODO showHelp() quit(1)

  case paramStr(1)
  of "connect":
    let ssid = paramStr(2)

    echo("Connecting...")
    if not connect(ssid):
      echo("Could not connect")

    echo("Restarting DHCP...")
    if not configureDHCP():
      echo("Could not configure DHCP")

    echo("Restarting DNS...")
    if not restartDNS():
      echo("Could not restart DNS")

main()
