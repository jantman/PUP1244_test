# == Class PUP1244::params
#
# This class is meant to be called from PUP1244
# It sets variables according to platform
#
class PUP1244::params {
  case $::osfamily {
    'Debian': {
      $package_name = 'PUP1244'
      $service_name = 'PUP1244'
    }
    'RedHat', 'Amazon': {
      $package_name = 'PUP1244'
      $service_name = 'PUP1244'
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
}
