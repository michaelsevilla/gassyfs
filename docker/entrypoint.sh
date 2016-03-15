#!/bin/bash
set -x
set -e

echo "=> Get the code (if we don't already have it)"
if [ -z "$SRC_DIR" ]; then
  SRC_DIR=/tmp/gassyfs
fi
if [ ! -d "$SRC_DIR/.git" ]; then
  git clone --recursive https://github.com/noahdesu/gassyfs.git $SRC_DIR
fi

echo "=> Build code without Lua..."
cd $SRC_DIR
GASNET=/usr/local make
#GASNET=/usr/local LUA_CPPFLAGS=/usr/include/lua5.2 make

echo "=> Setup fuse..."
echo user_allow_other | sudo tee -a /etc/fuse.conf
sudo cat /etc/fuse.conf || true
mkdir /mount

echo "=> Setup SSH..."
/configure_ssh.sh

if [ "$DAEMON" == "MASTER" ]; then
  echo "=> Start SSHD in the background..."
  /usr/sbin/sshd
  echo "=> Start gassyfs in the foreground..."
  SSH_SERVERS="localhost localhost" /usr/local/bin/amudprun -np 2 ./gassy /mount -o allow_other -o fsname=gassy -o atomic_o_trunc -o rank0_alloc
  /bin/bash
elif [ "$DAEMON" == "WORKER" ]; then
  echo "=> Start SSHD in the foreground..."
  exec /usr/sbin/sshd -D -d
else
  echo "=> ERROR: unknown daemon: $DAEMON"
  exit 1
fi
