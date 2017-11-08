Install and configure Satellite 6 on a RHEL 6 or 7 host.
====

This is based on the process outlined here:

https://access.redhat.com/documentation/en-US/Red_Hat_Satellite/6.2/html-single/Installation_Guide/index.html

Usage
=======
Invoke the role using only one of the below three include statements, in order to pass in the data required to register the system with RHN:


Usage with RHN username + password
---------------------------
```YAML
- hosts: satellite6.example.com
  inclure_role:
    name: role-satellite6-server
  vars:
    - rhn_user: "{{ rhn_username }}"
    - rhn_pass: "{{ rhn_password }}"
```

Usage with RHN activation key
-----------------------------
FIXME: has this one been tested? Using activation keys with RHSM needs an org_id...

```YAML
- hosts: satellite6.example.com
  inclure_role:
    name: role-satellite6-server
  vars:
    - rhn_activationkey: "{{ my_satellite_activation_key }}"
```

Usage with RHSM pools
---------------------
FIXME: do we really need this?
FXIME2: don't we need to use _also_ rhn_user & rhn_pass?

```YAML
- hosts: satellite6.example.com
  inclure_role:
    name: role-satellite6-server
  vars:
    - rhn_user: "{{ rhn_username }}"
    - rhn_pass: "{{ rhn_password }}"
    - rhn_pool_ids:
      - somelongpoolid
      - someotherlongpoolid
```


NB:
===
This role now depends on linux-system-roles.
