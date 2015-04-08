# Install the python module to test
include:
  - required-packages

cassandra-driver:
  pip.installed:
    - name: cassandra-driver
    - require:
      - sls: required-packages
