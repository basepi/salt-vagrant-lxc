{% for user in pillar['users'] %}
manage_{{ user }}:
  user.present:
    - name: {{ user }}
{% endfor %}
