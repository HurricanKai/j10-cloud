# -*- coding: utf-8 -*-
# vim: ft=yaml
---
alcali:
  service:
    name: alcali
    init_delay: null  # Gunicorn may take some delay to pop, adjust here
  deploy:
    repository: https://github.com/latenighttales/alcali.git
    rev: v3006.3.0
    force_reset: False
    user: alcali
    group: alcali
    directory: /opt/alcali
    runtime: python3
  gunicorn:
    name: 'config.wsgi:application'
    host: '0.0.0.0'
    port: 8000
    workers: {{ '{0:d}'.format((grains['num_cpus'] / 2) | int) }}
    timeout: 300
  config:
    allowed_hosts: '*'
    db_backend: postgresql
    db_name: salt
    db_user: alcali
    db_pass: d8df45aed3541fd9a062210ca4844a5b
    db_host: 127.0.0.1
    db_port: 5432
    master_minion_id: salt-master
    secret_key: 'd8df45aed3541fd9a062210ca4844a5b'
    salt_url: 'https://127.0.0.1:8080'
    salt_auth: rest