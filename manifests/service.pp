# == Class PUP1244::service
#
# This class is meant to be called from PUP1244
# It ensure the service is running
#
class PUP1244::service {

  service { $PUP1244::service_name:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
}
