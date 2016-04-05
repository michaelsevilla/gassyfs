#!/bin/bash
set -x
set -e

echo "=> Setting envars for INFINIBAND=$INFINIBAND"
N=`echo $SSH_SERVERS | wc -w`
export GASNET=/usr
export EXEC="/usr/bin/amudprun -np $N"
if [ "$INFINIBAND" == 1 ]; then
  export CONDUIT=ibv
  export GASNET_USE_XRC=0 
  export GASNET_SSH_SERVERS="$SSH_SERVERS"
  export EXEC="gasnetrun_ibv -v -np $N"
fi

echo "=> Get the code (if we don't already have it)"
if [ -z "$SRC_DIR" ]; then
  SRC_DIR=/tmp/gassyfs
fi
if [ ! -d "$SRC_DIR/.git" ]; then
  git clone --recursive https://github.com/noahdesu/gassyfs.git $SRC_DIR
  if [ "$INFINIBAND" == 1 ]; then
    cd $SRC_DIR
    git checkout -b infiniband remotes/origin/infiniband
  fi
fi

echo "=> Build code without Lua..."
cd $SRC_DIR
make

echo "=> Setup fuse..."
echo user_allow_other | sudo tee -a /etc/fuse.conf
sudo cat /etc/fuse.conf || true
mkdir /mount

echo "=> Setup SSH..."
/configure_ssh.sh

if [ "$DAEMON" == "MASTER" ]; then
  echo "=> Start SSHD in the background..."
  /usr/sbin/sshd
  ulimit -l unlimited

  echo "=> Start gassyfs in the foreground..."
  $EXEC ./gassy /mount $MOUNT_ARGS
elif [ "$DAEMON" == "WORKER" ]; then
  echo "=> Start SSHD in the foreground..."
  exec /usr/sbin/sshd -D
else
  echo "=> ERROR: unknown daemon: $DAEMON"
  exit 1
fi
