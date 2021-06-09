{% from "flannel/map.jinja" import flannel with context %}

include:
  - systemd/cmd

flanneld:
  file.managed:
    - name: {{ flannel.install_dir }}/flanneld
    - mode: 755
    - user: root
    - source: {{ flannel.source_url }}/{{ flannel.source_version }}/flanneld-{{ grains['osarch'] }}
    - source_hash: {{ flannel.source_hash }}
    - require_in:
      - file: flannel-systemd-unit-file

flannel-systemd-unit-file:
  file.managed:
    - name: /lib/systemd/system/flannel.service
    - source: salt://flannel/files/systemd/system/flannel.service.j2
    - template: jinja
    - require_in:
      - service: flannel-service-enable
      - file: docker-systemd-unit-file
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
