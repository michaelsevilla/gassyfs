#!/bin/bash
set -x
set -e

echo "=> Get the code (if we don't already have it)"
if [ -z "$SRC_DIR" ]; then
  SRC_DIR=/tmp/gassyfs
fi
if [ ! -d "$SRC_DIR/.git" ]; then
  git clone --recursive https://github.com/noahdesu/gassyfs.git $SRC_DIR
  cd $SRC_DIR
  git checkout -b infiniband remotes/origin/infiniband
fi

echo "=> Build code without Lua..."
cd $SRC_DIR
GASNET=/usr CONDUIT=ibv make

echo "=> Setup fuse..."
echo user_allow_other | sudo tee -a /etc/fuse.conf
sudo cat /etc/fuse.conf || true
mkdir /mount

echo "=> Setup SSH..."
/configure_ssh.sh

if [ "$DAEMON" == "MASTER" ]; then
  ulimit -l unlimited
  echo "=> Start SSHD in the background..."
  /usr/sbin/sshd
  echo "=> Start gassyfs in the foreground..."
  N=`echo $SSH_SERVERS | wc -w`
  GASNET_USE_XRC=0 GASNET_SSH_SERVERS="$SSH_SERVERS" gasnetrun_ibv -v -np $N ./gassy /mount -o allow_other -o fsname=gassy -o atomic_o_trunc
elif [ "$DAEMON" == "WORKER" ]; then
  echo "=> Start SSHD in the foreground..."
  exec /usr/sbin/sshd -D
else
  echo "=> ERROR: unknown daemon: $DAEMON"
  exit 1
fi
