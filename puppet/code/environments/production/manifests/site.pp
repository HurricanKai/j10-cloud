filebucket { 'main':
  path   => false,
}

File { backup => main, }

stage { 'pre-net':
  before => Stage['net']
}
stage { 'net':
  before => Stage['main']
}

$ssl_dir = $::settings::ssldir
node 'puppet-master' {
  $puppetboard_certname = 'puppet-master.local'

  include ntp_client
}

node default {
  include ntp_client

  # swap_file::files { 'default':
  #   ensure   => present,
  # }
}
