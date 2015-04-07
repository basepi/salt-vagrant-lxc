base:
  '*':
    - required-packages
    - cassandra.driver
  'roles:cassandra*':
    - match: grain
    - cassandra
