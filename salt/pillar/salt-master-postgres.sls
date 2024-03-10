# -*- coding: utf-8 -*-
# vim: ft=yaml
---
postgres:
  port: "5432"
  use_upstream_repo: true
  version: "16"

  service:
    name: postgresql

  acls:
    - ["host", "alcali", "alcali", "127.0.0.1/32", "md5"]

  users:
    alcali:
      ensure: present
      password: "d8df45aed3541fd9a062210ca4844a5b"
      encrypted: md5

  databases:
    alcali:
      owner: "alcali"
# vim: ft=yaml ts=2 sts=2 sw=2 et
