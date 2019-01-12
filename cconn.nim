import osproc, streams, strutils, os, nre, rdstdin

const WPA_SUPP_PATH = "/etc/wpa_supplicant"
const INTERFACE = "wlp2s0"

proc checkArgs(): bool =
  if paramCount() < 2:
    return false
  return true

proc scanSSIDs(): seq[string] =

  var ssids = newSeq[string]() 
  var l = ""
  let ps = startProcess("/sbin/iwlist", "", ["wlp2s0", "scan"])
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
  let (outp, exit) = execCmdEx(
    "wpa_supplicant -i " & INTERFACE & " -c " & WPA_SUPP_PATH & "/" & ssid & ".conf"
  )

  if exit > 0:
    echo("Could not connect with wpa_supplicant")
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

proc main(): void =

  if not checkArgs():
    # TODO showHelp()
    quit(1)

  case paramStr(1)
  of "connect":
    let ssid = paramStr(2)
    if not connect(ssid):
      echo("Could not connect")

main()
