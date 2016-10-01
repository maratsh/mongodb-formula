{%- from "mongodb/map.jinja" import ms with context -%}
{% from 'systemd/macro/tasks.sls' import systemd_tasks %}

mongos_package:
  pkg.installed:
    - name: {{ ms.mongos_package }}

mongos_user:
  user.present:
    - name: {{ ms.mongos_user }}
    - gid_from_name: True
    - home: {{ ms.mongos_user_home }}
    - shell: /bin/sh
    - system: True
    - require:
      - group: mongos_group

mongos_group:
  group.present:
    - name: {{ ms.mongos_group }}
    - system: True

{%- if 'path' in  ms.mongos_settings.systemLog %}
mongos_log_path:
  file.directory:
{%- if 'mongos_settings' in ms %}
    - name: {{ salt['file.dirname'](ms.mongos_settings.systemLog.path) }}
{%- else %}
    - name: {{ ms.log_path }}
{%- endif %}
    - user: {{ ms.mongos_user }}
    - group: {{ ms.mongos_group }}
    - mode: 755
    - makedirs: True
{% endif %}

{%- if grains['init'] != 'systemd' %}
mongos_init:
  file.managed:
    - name: /etc/init/mongos.conf
    - source: salt://mongodb/files/mongos.upstart.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
{% else %}
{{ systemd_tasks(ms.service) }}
{% endif %}
mongos_config:
  file.managed:
    - name: {{ ms.conf_path }}
    - source: salt://mongodb/files/mongos.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644

mongos_service:
  service.running:
    - name: {{ ms.mongos }}
    - enable: True
    - watch:
      - file: mongos_config
