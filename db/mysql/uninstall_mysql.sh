#!/bin/bash
apt-get remove mysql-server -y
apt-get autoremove -y
dpkg -l | grep mysql | grep ii