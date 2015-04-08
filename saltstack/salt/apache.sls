install_apache:
  pkg.installed:
    - name: apache2

apache_running:
  service.running:
    - name: apache2
    - enable: True
    - require:
      - pkg: install_apache
    - watch:
      - file: install_apache_conf

install_apache_conf:
  file.managed:
    - name: /etc/apache2/apache2.conf
    - source: salt://apache.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: install_apache
