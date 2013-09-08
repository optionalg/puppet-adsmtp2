class myadsmtp2 {
  package {
    "python-ldap": ensure => present;
  }

  file {'/etc/postfix/exchange':
    ensure => directory,
    owner => root,
    group => root;
  }

  file {'/usr/local/bin/getadsmtp.py':
    ensure => present,
    owner => root,
    group => root,
    mode => 0744,
    source => "puppet:///modules/myadsmtp2/getadsmtp.py";
  }
}

define myadsmtp2::register($dc, $user, $password, $ou, $transport='OK', $exchange=False, $port=636) {
  if $exchange == False {
    exec {"$dc-fetch":
      command => "getadsmtp.py --connect $dc --port $port --user $user --password $password --transport '$transport' --ou $ou > /tmp/exchange_$title";
    }
  } else {
    exec {"$dc-fetch":
      command => "getadsmtp.py --connect $dc --port $port --user $user --password $password --transport '$transport' --exchange --ou $ou > /tmp/exchange_$title";
    }
  }

  file {"/etc/postfix/exchange/$title":
    ensure => present,
    owner => root,
    group => root,
    mode => 0644,
    source => "/tmp/exchange_$title",
    require => Exec["$dc-fetch"],
    notify => Exec["$dc-postmap"];
  }

  exec {"$dc-postmap":
    command => "postmap /etc/postfix/exchange/$title",
    refreshonly => true,
    require => [File['/etc/postfix/exchange'], File["/etc/postfix/exchange/$title"]];
  }
}
