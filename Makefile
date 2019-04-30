#make
#make install
#make init
#make web
#make clean

CC = arm-linux-gnueabihf-gcc

productName = "productName:LTE-ROUTER"
productModle = "productModle:P17/0156_CPE_V2.2"
softVersion = "softVersion:P17/0156_cpe_2.5.0_"
kernel_dir = /home/xueqian/cpe_FileSystem/A7-linux-src/
rootfs_dir = /home/xueqian/cpe_FileSystem/rootfs/
cpe_flash_dir = /home/xueqian/ubuntushare/cpe_flash_dir
config = $(PWD)/config
log = $(PWD)/log
tmp = $(PWD)/tmp
init = $(PWD)/init
dtu = $(PWD)/dtu
security = $(PWD)/security
web = $(PWD)/web
webroot = $(web)/webroot
webServer = $(web)/websvr-goahead-4.0.2
webBin = $(webServer)/build/linux-arm-default/bin
webPage = $(web)/webPage
webserver = $(web)/websvr-goahead-2.18/LINUX
webpage = ~/ubuntushare/staticPage
opt = $(rootfs_dir)/../opt
package=/home/xueqian/ubuntushare/package

initEXE = lterouter
export initEXE
dtuEXE = suyi_dtu
export dtuEXE
webEXE = goahead
export webEXE

#readdr = root@90.1.2.1:/opt
readdr = root@192.168.1.1:/opt

all:
	$(MAKE) -C $(init)
	$(MAKE) -C $(dtu)
	cd $(webServer) && $(MAKE) CC=arm-linux-gnueabihf-gcc ARCH=arm  

config:
	echo $(productName) > $(config)/Version
	echo $(productModle) >> $(config)/Version
	echo "$(softVersion)`date +%Y%m%d`" >> $(config)/Version
	cp $(config)/* $(opt)/config/
	cp $(log)/* $(opt)/log/
	-cp $(tmp)/* $(opt)/tmp/
	scp -r $(config)/* $(readdr)/config

init:
	@echo $(DB);
	$(MAKE) -C $(init)
	cp $(init)/*.sh $(init)/button $(init)/$(initEXE) $(opt)/init/
	scp -r $(init)/*.sh $(init)/button $(init)/$(initEXE) $(readdr)/init/
	#cd $(init) && $(MAKE)
dtu:
	$(MAKE) -C $(dtu)
	cp $(dtu)/$(dtuEXE) $(opt)/dtu/
	scp -r $(dtu)/$(dtuEXE) $(readdr)/dtu/
	#cd $(init) && $(MAKE)

security:
	cp $(security)/* $(opt)/security/
	scp -r $(security)/* $(readdr)/security/
	#cd $(init) && $(MAKE)
	
web:
	cd $(webServer) && $(MAKE) CC=arm-linux-gnueabihf-gcc ARCH=arm  
	cp $(webServer)/src/auth.txt $(webServer)/src/route.txt $(webBin);
	cp -r $(webBin)/* $(opt)/web/webServer/
	cp -r $(webPage)/* $(opt)/web/webPage/
	scp -r $(webBin)/* $(readdr)/web/webServer/
	scp -r $(webPage)/* $(readdr)/web/webPage/

webPage:
	cp -r $(webPage)/* $(opt)/web/webPage/
	scp -r $(webPage)/* $(readdr)/web/webPage/

goahead2:
	cd $(webserver) && $(MAKE) 
	cp $(webserver)/$(webEXE) $(opt)/web/webServer
	cp -r $(webpage)/* $(opt)/web/staticPage
	scp $(webserver)/$(webEXE) $(readdr)/web/webServer
	scp -r $(webpage) $(readdr)/web/

clean:
	cd $(webServer) && $(MAKE) clean 
	cd $(init) && $(MAKE) clean 
	cd $(dtu) && $(MAKE) clean 

opt:
	rm $(opt)/* -rf
	-mkdir $(opt) $(opt)/config $(opt)/init $(opt)/security $(opt)/dtu $(opt)/web $(opt)/web/webServer $(opt)/web/webPage $(opt)/tmp $(opt)/log $(opt)/upgrade
	echo $(productName) > $(config)/Version
	echo $(productModle) >> $(config)/Version
	echo "$(softVersion)`date +%Y%m%d`" >> $(config)/Version
	cp $(config)/* $(opt)/config/
	cp $(log)/* $(opt)/log/
	-cp $(tmp)/* $(opt)/tmp/
	cp $(init)/*.sh $(init)/button $(init)/$(initEXE) $(opt)/init/
	cp $(dtu)/$(dtuEXE) $(opt)/dtu/
	cp $(security)/* $(opt)/security/
	cp $(webServer)/src/auth.txt $(webServer)/src/route.txt $(webBin);
	cp -r $(webBin)/* $(opt)/web/webServer/
	cp -r $(webPage)/* $(opt)/web/webPage/
#system.tar 恢复出厂设置使用 解压时必须进入对应的目录
	cd $(opt);tar -cf upgrade/config.tar ./config

#网页升级包，升级后删除
package:
	-rm  ~/ubuntushare/package/system/*
	-rm ~/ubuntushare/package/system.tar;
	tar -cf $(package)/system/cpe.tar -C $(opt) .;
	cd ~/ubuntushare/package/system/;md5sum cpe.tar > cpe.md5;
	cd $(package);tar -cf - system|openssl des3 -salt -k monkey | dd of=system.tar
	#dd if=system.tar |openssl des3 -d -k monkey|tar xf -
#make flash_file
	rm -rf $(cpe_flash_dir)/*;
	cd $(rootfs_dir)/;tar -zcf $(cpe_flash_dir)/rootfs.tar.gz ./*;
	cd $(kernel_dir)/arch/arm/boot/;tar -zcf $(cpe_flash_dir)/kernel.tar.gz ./zImage;
	cp $(kernel_dir)/arch/arm/boot/dts/imx6g2c-128m.dtb $(cpe_flash_dir);
	cp $(package)/system/cpe.tar $(cpe_flash_dir);

install:
	scp -r $(opt)/* $(readdr)

.PHONY:all clean config init dtu web install security
