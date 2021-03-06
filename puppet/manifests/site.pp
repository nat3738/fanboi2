node default {

  # Update only if PostgreSQL is not installed. Psql requires updating APT.
  exec {"apt-update":
    command => 'apt-get update',
    unless  => 'which psql',
    path    => '/usr/local/bin:/usr/bin:/bin',
    timeout => 0,
  }

  # Run apt before all installations via apt.
  Exec["apt-update"] -> Package <| |>

  # Runtime requirements (database, assets compiler, etc.)
  class {'redis':}
  class {'nodejs': node_ver => 'v0.10.0'}
  class {'postgresql::server':}
  class {'postgresql::devel':}
  class {'python3':}

  # Setup database for development environment and test environment.
  postgresql::db {'fanboi2_dev':  user => 'fanboi2', password => 'dev'}
  postgresql::db {'fanboi2_test': user => 'fanboi2', password => 'dev'}

  # Assets packages and ensure they're installed after NodeJS.
  package {['brunch']:
    ensure   => present,
    provider => 'npm',
    require  => Class['nodejs'],
  }

  # Setup Python virtual environment.
  python3::venv {'fanboi2':
    path        => '/usr/local/venv/fanboi2/',
    python      => 'python3',
    user        => 'vagrant',
    system_site => true,
  }

  # Some project settings.
  $fb2_venv = '/usr/local/venv/fanboi2/'
  $fb2_root = '/vagrant/'
  $fb2_user = 'vagrant'

  # Setup project as development mode (i.e. python setup.py develop).
  python3::setup {'fanboi2':
    mode     => 'develop',
    setup    => "setup.py",
    venv     => $fb2_venv,
    user     => $fb2_user,
    cwd      => $fb2_root,
    require  => [Python3::Venv['fanboi2'], Class['postgresql::server']],
  }

  # Migration!
  exec {'fanboi2-migrate':
    command  => "${fb2_venv}bin/alembic upgrade head",
    user     => $fb2_user,
    cwd      => $fb2_root,
    require  => [Postgresql::Db['fanboi2_dev'], Python3::Setup['fanboi2']],
  }

  # Assets setup.
  exec {'fanboi2-assets':
    command  => 'npm install',
    user     => $fb2_user,
    cwd      => $fb2_root,
    path     => '/usr/local/bin:/usr/bin:/bin',
    require  => Python3::Setup['fanboi2'],
  }

  # Actually running stuff.
  class {'supervisord':}
  class {'supervisord::inet':}

  supervisord::program {'watch':
    command  => 'brunch watch',
    user     => $fb2_user,
    cwd      => $fb2_root,
    require  => Exec['fanboi2-assets'],
  }

  supervisord::program {'pserve':
    command  => "${fb2_venv}bin/pserve development.ini --reload",
    user     => $fb2_user,
    cwd      => $fb2_root,
    require  => [Exec['fanboi2-migrate'], Python3::Setup['fanboi2']],
  }

}
