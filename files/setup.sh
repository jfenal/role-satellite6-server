#!/bin/bash
# vim: ts=2 sw=2 et

# nmcli c add type 802-3-ethernet ifname eth1 autoconnect yes save yes
#
#
#
#
# subscription-manager register --username=rhn-gps-jfenal
# pool=$(LANG=C subscription-manager list --available --all | perl -n00e '$pool=$1 if /Satellite/ and /Pool ID:\s+(.*)\n/; END {print $pool}')
# pool=$(echo $(LANG=C subscription-manager list --available --all | awk -vRS= '/Red Hat Satellite/ { print $0 }' | grep 'Pool ID' | awk -F': ' '{print $2}'| tail -1))
#
# subscription-manager subscribe --pool="$pool"
#
# subscription-manager repos --disable "*"
#
# subscription-manager repos --enable rhel-7-server-rpms \
#   --enable rhel-server-rhscl-7-rpms \
#   --enable rhel-7-server-satellite-6.2-rpms
#
# yum -y install ipa-client ipa-admintools
# ipa-client-install
#
#
# yum -y update
# yum -y install satellite dhcpd
#
# systemctl start firewalld.service
# systemctl enable firewalld.service
#
# #firewall-cmd --permanent --add-port="443/tcp" --add-port="5671/tcp" --add-port="80/tcp" \
# #  --add-port="8140/tcp" --add-port="9090/tcp" --add-port="8080/tcp" --add-port="69/udp" \
# #  --add-port="53/tcp" --add-port="53/udp" --add-port="67/udp" --add-port="68/udp" --add-port="5674/tcp" \
# #  && firewall-cmd --reload
#
# firewall-cmd --add-service=RH-Satellite-6
# firewall-cmd --permanent --add-service=RH-Satellite-6
#
# # Si Capsule
# firewall-cmd --add-port="5646/tcp"
# firewall-cmd --permanent --add-port="5646/tcp"
#
#
# yum install -y chronyd
# systemctl enable chronyd
# systemctl start chronyd
#
# yum install -y sos
#
#
# DOMAIN=example.com
# IDMSERVER=192.168.122.154


# configuration IPA pour Satellite
foreman-prepare-realm admin realm-capsule

mv /root/freeipa.keytab /etc/foreman-proxy
cp /var/log/freeipa.keytab /etc/foreman-proxy
chown foreman-proxy:foreman-proxy /etc/foreman-proxy/freeipa.keytab


satellite-installer --scenario satellite \
  --foreman-initial-organization ""${my_org}"" \
  --foreman-initial-location "Paris" \
  --foreman-admin-username ex-admin \
  --foreman-admin-password Passw0rd:


cat << EOF > /dev/null
Installing             Debug: Executing '/usr/sbin/foreman-rake -- config [99%] [...................Installing
Done                                               [100%] [............................................]
  Success!
  * Satellite is running at https://sat6.example.com
      Initial credentials are ex-admin / Passw0rd:
  * To install additional capsule on separate machine continue by
    running:

      capsule-certs-generate --capsule-fqdn "$CAPSULE" --certs-tar
"~/$CAPSULE-certs.tar"

  The full log is at /var/log/foreman-installer/satellite.log
EOF


#==================
#On the Satellite


#
# Create organization
#

my_org="Home"
export my_org
#
# Add Hammer defaults
#
mkdir ~/.hammer
cat << EOF > ~/.hammer/cli_config.yml
:modules:
    - hammer_cli_foreman

:foreman:
    :host: 'https://sat6.example.com/'
    :username: 'ex-admin'
    :password: 'Passw0rd:'
    :organization-label: '${my_org}'

:log_dir: '~/.hammer/log'
:log_level: 'error'
EOF

hammer organization create --name="${my_org}" --label=local_org
# hammer organization add-user --user=org-admin --name="${my_org}"

hammer location create --name=Home
# hammer location add-user --name=Laptop --user=ex-admin
hammer location add-organization --name=Home --organization="${my_org}"



hammer defaults add --param-name organization_name  --param-value "${my_org}"
hammer defaults add --param-name location_name      --param-value Home
hammer defaults list


hammer domain create --name='example.com'          --organizations="${my_org}" --locations=Laptop
hammer domain create --name='internal.example.com' --organizations="${my_org}" --locations=Laptop

hammer subnet create --boot-mode=DHCP --dns-primary=192.168.122.154 --domains=example.com --gateway=192.168.122.1  --locations=Laptop \
  --organizations="${my_org}" --name=default --network=192.168.122.0 --mask=255.255.255.0

hammer subnet create --boot-mode=DHCP --dns-primary=192.168.122.154 --domains=internal.example.com --gateway=172.31.0.1  --locations=Laptop \
  --organizations="${my_org}" --name=internal-nat --network=172.31.0.0 --mask=255.255.0.0


#
# Configure and synchronise repositories
#

hammer repository-set enable --organization "${my_org}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server (RPMs)'
#hammer repository-set enable --organization "${my_org}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server - Fastrack (RPMs)'
hammer repository-set enable --organization "${my_org}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server - Optional (RPMs)'
hammer repository-set enable --organization "${my_org}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server - Extras (RPMs)'
hammer repository-set enable --organization "${my_org}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server - RH Common (RPMs)'
hammer repository-set enable --organization "${my_org}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server - Supplementary (RPMs)'
#hammer repository-set enable --organization "${my_org}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'RHN Tools for Red Hat Enterprise Linux 7 Server (RPMs)'
hammer repository-set enable --organization "${my_org}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server (ISOs)'
hammer repository-set enable --organization "${my_org}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server (Kickstart)'

hammer repository-set enable --organization "${my_org}" --product 'Red Hat Software Collections for RHEL Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Software Collections RPMs for Red Hat Enterprise Linux 7 Server'

hammer repository-set enable --organization "${my_org}" --product 'Red Hat Satellite' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Satellite 6.2 (for RHEL 7 Server) (RPMs)'
hammer repository-set enable --organization "${my_org}" --product 'Red Hat Satellite Capsule' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Satellite Capsule 6.2 (for RHEL 7 Server) (RPMs)'

hammer repository-set enable --organization "${my_org}" --product 'Red Hat OpenShift Enterprise' --basearch='x86_64' --releasever='7Server' --name 'Red Hat OpenShift Enterprise 3.2 (RPMs)'

hammer product create --name='Forge' --organization="${my_org}"
hammer repository create --name='Puppet Forge' --organization="${my_org}" --product='Forge' --content-type='puppet' --publish-via-http=true --url=https://forge.puppetlabs.com
hammer product create --name='EPEL' --organization="${my_org}"
hammer repository create --name='EPEL 7 - x86_64' --organization="${my_org}" --product='EPEL' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/epel/7/x86_64/

#
# Docker registry
#

hammer docker registry create --name="Red Hat Registry" --url="https://registry.access.redhat.com/" --description="Red Hat Registry" --locations="Laptop" --organizations=""${my_org}""


#
# synchronise repos
#

for i in $(hammer --csv repository list --organization="${my_org}" | head -2 | awk -F, {'print $1'} | grep -vi '^Id')
do
  hammer repository synchronize --id ${i} --organization="${my_org}" --async
done

#
# Sync plan
#

hammer sync-plan  create --name Daily --interval daily --enabled yes --sync-date 22:00:00 --organization "${my_org}"

hammer product set-sync-plan --sync-plan=Daily --organization="${my_org}" --name='Red Hat Enterprise Linux Server'
hammer product set-sync-plan --sync-plan=Daily --organization="${my_org}" --name='Red Hat OpenShift Enterprise'
hammer product set-sync-plan --sync-plan=Daily --organization="${my_org}" --name='Red Hat Satellite'
hammer product set-sync-plan --sync-plan=Daily --organization="${my_org}" --name='Red Hat Satellite Capsule'
hammer product set-sync-plan --sync-plan=Daily --organization="${my_org}" --name='Red Hat Software Collections for RHEL Server'
hammer product set-sync-plan --sync-plan=Daily --organization="${my_org}" --name='Forge'
hammer product set-sync-plan --sync-plan=Daily --organization="${my_org}" --name='EPEL'

#
# Lifecycle environment
#

hammer lifecycle-environment create --name='DEV' --prior='Library'  --organization="${my_org}"
hammer lifecycle-environment create --name='PRE' --prior='DEV'      --organization="${my_org}"
hammer lifecycle-environment create --name='PRO' --prior='PRE'      --organization="${my_org}"


#
# Content view
#

hammer content-view create --name='rhel-7-server-x86_64-cv' --organization="${my_org}"
for i in $(hammer --csv repository list --organization="${my_org}" | grep -v Forge | awk -F, {'print $1'} | grep -vi '^ID')
do
   hammer content-view add-repository --name='rhel-7-server-x86_64-cv' --organization="${my_org}" --repository-id=${i}
done

hammer content-view publish --name="rhel-7-server-x86_64-cv" --organization="${my_org}" --async

CVersion=$(hammer  --csv content-view  version list | grep "rhel-7-server-x86_64-cv" | awk -F, '{print $3}')

hammer content-view version promote --organization="${my_org}" --to-lifecycle-environment="DEV" --content-view="rhel-7-server-x86_64-cv"
hammer content-view version promote --organization="${my_org}" --to-lifecycle-environment="PRE" --content-view="rhel-7-server-x86_64-cv"
hammer content-view version promote --organization="${my_org}" --to-lifecycle-environment="PRO" --content-view="rhel-7-server-x86_64-cv"




hammer host-collection create --name='RHEL 7 x86_64' --organization="${my_org}"

# Create an activation key for our environments:

hammer activation-key create --name='rhel-7-server-x86_64-ak-dev' --organization="${my_org}" --content-view='rhel-7-server-x86_64-cv' --lifecycle-environment='DEV'
hammer activation-key create --name='rhel-7-server-x86_64-ak-pre' --organization="${my_org}" --content-view='rhel-7-server-x86_64-cv' --lifecycle-environment='PRE'
hammer activation-key create --name='rhel-7-server-x86_64-ak-pro' --organization="${my_org}" --content-view='rhel-7-server-x86_64-cv' --lifecycle-environment='PRO'

# Associate each activation key to our host collection:

hammer activation-key add-host-collection --name='rhel-7-server-x86_64-ak-dev' --host-collection='RHEL 7 x86_64' --organization="${my_org}"
hammer activation-key add-host-collection --name='rhel-7-server-x86_64-ak-pre' --host-collection='RHEL 7 x86_64' --organization="${my_org}"
hammer activation-key add-host-collection --name='rhel-7-server-x86_64-ak-pro' --host-collection='RHEL 7 x86_64' --organization="${my_org}"

#  And we add all subscriptions that we have available to our keys:

for i in $(hammer --csv activation-key list --organization="${my_org}" | awk -F, {'print $1'} | grep -vi '^ID')
do
  for j in $(hammer --csv subscription list --organization="${my_org}"  | awk -F, {'print $8'} | grep -vi '^ID')
  do
    hammer   activation-key add-subscription --id ${i} --subscription-id ${j}
  done
done


# Associate a partition table to OS:

PARTID=$(hammer --csv partition-table list | grep 'Kickstart default' | awk -F, {'print $1'})
for i in $(hammer --csv os list | awk -F, {'print $1'} | grep -vi '^ID')
do
  hammer partition-table add-operatingsystem --id="${PARTID}" --operatingsystem-id="${i}"
done


# Associate kickstart PXE template to OS:

PXEID=$(hammer --csv template list | grep 'Kickstart default PXELinux' | awk -F, {'print $1'})
SATID=$(hammer --csv template list | grep 'Satellite Kickstart Default' | awk -F, {'print $1'})
for i in $(hammer --csv os list | awk -F, {'print $1'} | grep -vi '^ID')
do
  hammer template add-operatingsystem --id="${PXEID}" --operatingsystem-id="${i}"
  hammer os set-default-template --id="${i}" --config-template-id="${PXEID}"
  hammer os add-config-template --id="${i}" --config-template-id="${SATID}"
  hammer os set-default-template --id="${i}" --config-template-id="${SATID}"
done

# And we create a RHEL7 hostgroup:

MEDID=$(hammer --csv medium list | grep 'Red_Hat_7_Server_Kickstart_x86_64_7Server' | awk -F, {'print $1'})
ENVID=$(hammer --csv environment list | grep rhel_7_server_x86_64  | grep -i dev | grep -v epel | awk -F, {'print $1'})
PARTID=$(hammer --csv partition-table list | grep 'Kickstart default' | awk -F, {'print $1'})
OSID=$(hammer --csv os list | grep 'RedHat 7.0' | awk -F, {'print $1'})
CAID=1
PROXYID=1
hammer hostgroup create --architecture="x86_64" --domain="${DOM}" --environment-id="${ENVID}" --medium-id="${MEDID}" --name="${HGRHEL6DEV}" --subnet="${NETNAME}" --ptable-id="${PARTID}" --operatingsystem-id="${OSID}" --puppet-ca-proxy-id="${CAID}" --puppet-proxy-id="${PROXYID}"



#
# Compute resource
#
hammer compute-resource create --name="laptop" --provider Libvirt --display-type SPICE --locations Paris --url='qemu+tcp://192.168.122.1/system' --organizations "${my_org}"
