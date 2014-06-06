TEST
====
Cinder卷迁移
Openstack支持不同后端间的卷迁移，Cinder中的卷迁移流程如下：
（1）存储后端自身提供卷迁移，这种方式需要存储后端支持卷迁移特性。在LVM存储后端中，源卷和目的卷需在同一个服务器上的不同backend上，且当前卷未挂载的情况下， LVM可通过自身迁移的方式迁移卷。
（2）如果存储后端不支持迁移特性，则通过Host完成卷迁移，分为两种情况：
（a）当前卷处于未挂载状态，则通过块存储服务将原卷的数据拷贝到目的卷。
（b）当前卷处于挂载状态，则通过Nova计算节点进行卷的热迁移（利用Libvirt中卷的热迁移特性进行迁移）。
Cinder中卷迁移的核心函数调用关系如下图所示：




                            VolumeManager
                           migrate_volume()
                                 |
                       +--------------------+
                   ①  |                    |
           force_host_copy=False         not moved   
                       |                    |
                 LVMISCSIDriver        VolumeManager                          
            driver.migrate_volume()  _migrate_volume_generic()                 
                       |                    |
             volutils.copy_volume()   rpcapi.create_volume()
                   dd命令拷贝               |                                   
                                            |                                   
                              +--------------------------+
                          ②  |                          |  ③                  
                           not attach                 attached
                              |                          |                       
                         VolumeDriver          nova_api.update_server_volume()
                   driver.copy_volume_data()             |             
                              |                          |
                         VolumeDriver               ComputeManager        
                   self._attach_volume(dest_vol)     swap_volume()        
                   self._attach_volume(src_vol)          |
                              |                          |                 
                  volume_utils.copy_volume()        LibvirtDriver
                            dd命令               driver.swap_volume()
                              |                          |
                         VolumeDriver                    |                      
                   self._detach_volume(src_vol)          |
                   self._detach_volume(dest_vol)   domain.blockRebase()  

说明：
	force_host_copy表示是否强制通过Host进行卷的迁移动作
	force_host_copy默认值为false，则首先会进入流程①，如果底层存储不支持卷迁移或迁移失败，则返回not moved，进入流程②或③
	卷的冷迁移最终都是采用dd命令完成
	若当前卷处于挂载状态，则通过Nova进行迁移（流程③），最终调用Libvirt接口进行热迁移
