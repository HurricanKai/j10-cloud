# TODO: Upgrade to hosting our own ntp server(s) on the backbone
class ntp_client {
    class { 'ntp':
        servers => [ '0.ch.pool.ntp.org', '1.ch.pool.ntp.org', '2.ch.pool.ntp.org', '3.ch.pool.ntp.org' ],
        stage   => 'pre-net',
    }
}
