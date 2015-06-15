#!/bin/bash
rpm -ivh openstack-heat-plugin-heat_docker-2014.2.4.dev8-1.1.x86_64.rpm  python-docker-py-0.5.3-2.3.x86_64.rpm  python-websocket-client-0.23.0-2.3.x86_64.rpm --nodeps --force
cp client.py /usr/lib64/python2.6/site-packages/docker/
heatControl -A RESTART
