# -*- coding: utf-8 -*-
# vim: ft=yaml
---
include:
  - alcali
  - postgres

# This makes sure alcali is only started & migrated after postgresql is already up! (or at least I hope so :)
# extend alcali-config-migrate-db-provision-cmd-run to depend on postgresql-running
alcali-after-postgres:
  test.nop:
    - require:
        - service: postgresql-running
        - postgres_database: postgres_database-alcali
    - require_in:
        - cmd: alcali-config-migrate-db-provision-cmd-run
# create-super-user:
#   cmd.run:
#     - name: sh -c "env DJANGO_SUPERUSER_USERNAME=admin DJANGO_SUPERUSER_EMAIL=admin@kaij.party DJANGO_SUPERUSER_PASSWORD=c0cf93cee41178209205d3c503875a ./code/manage.py createsuperuser --noinput"
#     - cwd: /opt/alcali/ # alcali.deploy.directory }}
#     - prepend_path: /opt/alcali/.venv/bin/ # alcali.deploy.directory }}/.venv/bin/
#     - runas: alcali # alcali.deploy.user }}
