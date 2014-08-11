# == Class PUP1244::install
#
class PUP1244::install {

  package { $PUP1244::package_name:
    ensure => present,
  }
}
