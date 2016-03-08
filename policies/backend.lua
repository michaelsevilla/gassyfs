os.execute("mkdir /mnt/cephfs")
os.execute("/ceph/src/ceph-fuse -d /mnt/cephfs &")
os.execute("sleep 3")

ret = 0
local f = io.open("/mnt/cephfs/remotefile", "r")
if f ~=nil then
  io.close(f)
else
  ret = -1
end
os.execute("umount /mnt/cephfs")
return ret
