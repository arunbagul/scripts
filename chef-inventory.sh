#!/bin/bash

# Author: Arun Bagul

knife search node 'name:*' -a os_version -a os -a platform_family -a platform_version -a platform  -a kernel.name -a kernel.release -a kernel.machine -a kernel.version  -a network -a dmi.system.all_records -a fqdn -a memory -a cpu -Fj > /var/www/html/chef_data/inventory.json 2>/dev/null 2>&1

