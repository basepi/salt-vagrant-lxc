# This state assumes python is installed.
# TODO: ensure the correct version of python is installed
#       Perhaps RedHat and Debian detection is sufficient.

required_pkgs:
  pkg.installed:
    - refresh: True
    - pkgs:
      - git
      - wget
      - python
      - python-dev
      - python-pip
      - python-zmq
      - python-yaml
      - python-msgpack
      - python-m2crypto
      - python-jinja2
      - python-blist
      - python3
      - python3-dev
      - python3-pip
      - python3-zmq
      - python3-yaml
      - python3-msgpack
      - python3-tornado
