# Install Oracle Java - 
# ---------------------

# OS agnostic method (tarball install)
# ------------------------------------
# A file (tar, rpm, deb) has to be downloaded in all cases
# Might as well use a method that will work on all 64 bit linux distros.

install-java:
  cmd.run:
    - name: |
        cd /tmp
        mkdir -p /usr/lib/jvm
        if test -e /srv/downloads/server-jre-8u40-linux-x64.tar.gz
        then
            cp /srv/downloads/server-jre-8u40-linux-x64.tar.gz ./
        else
            wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u40-b26/server-jre-8u40-linux-x64.tar.gz
        fi
        tar xzf server-jre-8u40-linux-x64.tar.gz -C /usr/lib/jvm
        update-alternatives --install "/usr/bin/java" "java" "/usr/lib/jvm/jdk1.8.0_40/bin/java" 1
        update-alternatives --set java /usr/lib/jvm/jdk1.8.0_40/bin/java
    - cwd: /tmp
    - shell: /bin/bash
    - timeout: 600
    - reload_modules: true
    - unless: test -x /usr/lib/jvm/jdk1.8.0_40
