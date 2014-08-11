# == Class: PUP1244
#
# Full description of class PUP1244 here.
#
# === Parameters
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#
class PUP1244 (
  $package_name = $PUP1244::params::package_name,
  $service_name = $PUP1244::params::service_name,
) inherits PUP1244::params {

  # validate parameters here

  class { 'PUP1244::install': } ->
  class { 'PUP1244::config': } ~>
  class { 'PUP1244::service': } ->
  Class['PUP1244']
}
