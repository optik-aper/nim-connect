import
  osproc

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


discard restartDNS()
