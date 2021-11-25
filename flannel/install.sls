{% from "flannel/map.jinja" import flannel with context %}

{% from "flannel/vars.jinja" import
    package_source, package_source_hash,
    flanneld_bin_path
with context %}

include:
  - systemd/cmd

flanneld:
  file.managed:
    - name: {{ flanneld_bin_path }}
    - mode: 755
    - user: root
    - source: {{ package_source }}
    - source_hash: {{ package_source_hash }}
    - require_in:
      - file: flannel-systemd-unit-file

flannel-systemd-unit-file:
  file.managed:
    - name: /lib/systemd/system/flannel.service
    - source: salt://flannel/files/systemd/system/flannel.service.j2
    - template: jinja
    - require_in:
      - service: flannel-service-enable
      - file: docker-systemd-drop-in
    - watch_in:
      - module: systemctl-reload

flannel-service-enable:
  service.enabled:
    - name: flannel
    - require_in:
      - service: flannel-service-running

flannel-service-running:
  service.running:
    - name: flannel
    - watch:
      - file: flannel-systemd-unit-file
      - file: flanneld
    - watch_in:
      - service: docker-service-running
