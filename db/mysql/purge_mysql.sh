#!/bin/bash
echo PURGE | sudo debconf-communicate mysql-server
apt purge mysql-client mysql-server