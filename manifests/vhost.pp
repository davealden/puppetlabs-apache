# Definition: apache::vhost
#
# This class installs Apache Virtual Hosts
#
# Parameters:
# - The $port to configure the host on
# - The $docroot provides the DocumentationRoot variable
# - The $ssl option is set true or false to enable SSL for this Virtual Host
# - The $template option specifies whether to use the default template or override
# - The $priority of the site
# - The $serveraliases of the site
# - The $options for the given vhost
# - The $vhost_name for name based virtualhosting, defaulting to *
#
# Actions:
# - Install Apache Virtual Hosts
#
# Requires:
# - The apache class
#
# Sample Usage:
#  apache::vhost { 'site.name.fqdn':
#    priority => '20',
#    port => '80',
#    docroot => '/path/to/docroot',
#  }
#
define apache::vhost(
    $port,
    $docroot,
    $ssl           = $apache::params::ssl,
    $template      = $apache::params::template,
    $priority      = $apache::params::priority,
    $servername    = $apache::params::servername,
    $serveraliases = $apache::params::serveraliases,
    $auth          = $apache::params::auth,
    $redirect_ssl  = $apache::params::redirect_ssl,
    $options       = $apache::params::options,
    $vdir          = $apache::params::vdir,
    $vhost_name    = $apache::params::vhost_name
  ) {

  include apache

  if $servername == '' {
    $srvname = $name
  } else {
    $srvname = $servername
  }

  if $ssl == true {
    include apache::ssl
  }

  # Since the template will use auth, redirect to https requires mod_rewrite
  if $redirect_ssl == true {
    case $operatingsystem {
      'debian','ubuntu': {
        A2mod <| title == 'rewrite' |>
      }
      default: { }
    }
  }

  file {
    "${vdir}/${priority}-${name}.conf":
      content => template($template),
      owner   => 'root',
      group   => 'root',
      mode    => '755',
      require => Package['httpd'],
      notify  => Service['httpd'];
    "${vdir}/vhosts/${priority}-${name}":
      ensure => directory;
  }

  if ! defined(Firewall["0100-INPUT ACCEPT $port"]) {
    @firewall {
      "0100-INPUT ACCEPT $port":
        jump  => 'ACCEPT',
        dport => "$port",
        proto => 'tcp'
    }
  }
}

