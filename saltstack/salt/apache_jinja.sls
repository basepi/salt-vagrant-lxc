{% if grains['os_family'] == 'Debian' %}
{% set apache_pkg = 'apache2' %}
{% set apache_conf = '/etc/apache2/apache2.conf' %}
{% set apache_conf_source = 'salt://apache.conf' %}
{% elif grains['os_family'] == 'RedHat' %}
{% set apache_pkg = 'httpd' %}
{% set apache_conf = '/etc/httpd/conf/httpd.conf' %}
{% set apache_conf_source = 'salt://httpd.conf' %}
{% endif %}

install_apache:
  pkg.installed:
    - name: {{ apache_pkg }}

apache_running:
  service.running:
    - name: {{ apache_pkg }}
    - enable: True
    - require:
      - pkg: install_apache
    - watch:
      - file: install_apache_conf

install_apache_conf:
  file.managed:
    - name: {{ apache_conf }}
    - source: {{ apache_conf_source }}
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: install_apache
