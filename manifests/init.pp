class nginxproxy(
  $conf_dir              = "/etc/nginx",
  $worker_threads        = undef,
  $server_name           = undef,
  $backend               = undef,
  $lb_style              = undef,
  $upstreams             = undef,
  $upstream_port         = undef,
  $upstream_fail_timeout = undef,
  $proxy_timeout         = undef,
  $listen_port           = "80",
  $rewrite_port          = "443",
  )  {
  include wildcardssl
  include iptables

  iptables::rule_fragment { '10web':
    source  => 'puppet:///modules/nginxproxy/web.rules',
  }

  iptables::rule_fragment { '20status':
    source => 'puppet:///modules/nginxproxy/status.rules'
  }

  package { 'nginx':  ensure => installed, }

  #file { $conf_dir:
  #  ensure => directory,
  #  owner  => 'nginx',
  #  group  => 'nginx',
  #  before => Package['nginx'],
  #}

  file { "${conf_dir}/conf.d":
    ensure => directory,
    owner  => 'nginx',
    group  => 'nginx',
    before => File[$conf_dir],
  }

  file { 'nginx.conf':
    path    =>  "${conf_dir}/nginx.conf",
    owner   => 'nginx',
    group   => 'nginx',
    content => template('nginxproxy/nginx.conf.erb'),
    before  => File[$conf_dir],
    notify  => Service['nginx'],
  }

  file { 'lb.conf':
    path    =>  "${conf_dir}/conf.d/lb.conf",
    owner   => 'nginx',
    group   => 'nginx',
    content => template('nginxproxy/conf.d/lb.conf.erb'),
    before  => File["${conf_dir}/conf.d"],
    notify  => Service['nginx'],
  }

  file { 'server.conf':
    path    =>  "${conf_dir}/conf.d/${server_name}.conf",
    owner   => 'nginx',
    group   => 'nginx',
    content => template('nginxproxy/conf.d/server.conf.erb'),
    before  => File["${conf_dir}/conf.d"],
    notify  => Service['nginx'],
  }

  service { 'nginx':
    ensure     => running,
    enable     => true,
    require    => [Package["nginx"], File['nginx.conf'], File['lb.conf'], File['server.conf']],
    hasrestart => true,
  }

}
