#
# According to Makefile.in, update all images and then produce Image File
#

include ../Makefile.in
include packages/$(TARGET)/Makefile.in
include configuration.in

QUIET = @
SHELL=/bin/bash

ifeq ($(layout_type), '')
LAYOUT:=nand
else
LAYOUT:=$(layout_type)
endif

ifeq ($(layout_use_emmc_swap), '')
LAYOUT_USE_EMMC_SWAP:=emmc_swap_false
else
LAYOUT_USE_EMMC_SWAP:=emmc_swap_$(layout_use_emmc_swap)
endif

TMP:=$(CURDIR)/tmp
ifeq ($(LAYOUT), )
  $(error No LAYOUT found.)
endif

ifneq ($(CUSTOMER_ID), )
  CUSTOMER_FOLDER := packages/$(TARGET)/customer/$(CUSTOMER_ID)
else
  ifeq ($(LAYOUT), nand)
    ifeq ($(ANDROID_IMGS), y)
    CUSTOMER_ID := rtk_generic
    else ifeq ($(NAS_IMGS), y)
    CUSTOMER_ID := rtk_generic_slc
    else ifeq ($(LNX_IMGS), y)
    CUSTOMER_ID := rtk_generic
    endif
  else ifeq ($(LAYOUT), emmc) # emmc 4GB
    ifeq ($(layout_size), 4gb)
    CUSTOMER_ID := rtk_generic_emmc
    else ifeq ($(layout_size), 8gb)
    CUSTOMER_ID := rtk_generic_emmc_8gb
    else ifeq ($(layout_size), 16gb)
    CUSTOMER_ID := rtk_generic_emmc_16gb
    else ifeq ($(layout_size), 32gb)
    CUSTOMER_ID := rtk_generic_emmc_32gb
    endif
    ifeq ($(ANDROID_IMGS), n)
      ifeq ($(NAS_IMGS), y)
        ifeq ($(DUAL_BOOT), y)
      CUSTOMER_ID := rtk_generic_emmc_dual
        else
      CUSTOMER_ID := rtk_generic_emmc_nas
        endif
      endif
    endif
  else ifeq ($(LAYOUT), sata)
    CUSTOMER_ID := rtk_generic_sata
  else ifeq ($(LAYOUT), spi)
    CUSTOMER_ID := rtk_generic_spi
  endif
  CUSTOMER_FOLDER := packages/$(TARGET)/customer/$(CUSTOMER_ID)
endif

#### Utilities
OPENSSL = openssl
DUMMY_TARGET       = $(LAYOUT).uImage
GEN_RSA_PATTERN     = $(CURDIR)/bin/gen_rsa_pattern.pl
ifeq ($(chip_rev), 1)
GEN_RSA_PATTERN64   = $(CURDIR)/bin/gen_rsa_pattern64_0000.pl
else
GEN_RSA_PATTERN64   = $(CURDIR)/bin/gen_rsa_pattern64_0001.pl
endif
REAL_RSA_OUT        = msg.bin
RRMODN              = RRModN.bin
NP_INV32            = np_inv32.bin
TMP_RSA_OUT         = rsa_enc.bin
#### 
LIBFILE=`cat packages/$(TARGET)/system/vendor/lib/mediadrm/lib.List`
TAFILE=`ls packages/$(TARGET)/system/lib/teetz`
MYZLIB_PATH = $(CURDIR)/bin/myzlib
E2FSCK_PATH = $(CURDIR)/bin/e2fsck
MKE2FS_PATH = $(CURDIR)/bin/mke2fs
MAKE_EXT4FS = $(CURDIR)/bin/make_ext4fs
SIMG2IMG = $(CURDIR)/bin/simg2img
RESIZE2FS_PATH = $(CURDIR)/bin/resize2fs
MKSQUASHFS_PATH = $(CURDIR)/bin/mksquashfs
MKYAFFS2IMAGE_PATH = $(CURDIR)/bin/mkyaffs2image
RTSSL_PATH = $(CURDIR)/bin/RtSSL
MKUBIFS_PATH := $(CURDIR)/bin/mkfs.ubifs
UBINIZE_PATH := $(CURDIR)/bin/ubinize
DO_SHA256_PATH := $(CURDIR)/bin/do_sha256
SHA_REVERSE_PATH := $(CURDIR)/bin/reverse_rsa_data.pl
REVERSE_PL := $(CURDIR)/bin/reverse.pl
STR2BIN_PATH := $(CURDIR)/bin/str2bin.pl
RUNCMD_PATH := $(CURDIR)/bin/runCmd.pl
FDTGET_PATH := $(CURDIR)/bin/fdtget
LIB_ENC_PATH := $(CURDIR)/bin/lib_encryptor
OBFUSE_PATH := $(CURDIR)/bin/obfuse
OBFUSE_2_PATH := $(CURDIR)/bin/obfuse_0002
OBFUSE_H_CBC  := $(CURDIR)/bin/obfuse_h_cbc
GZIP_PATH := $(CURDIR)/bin/minigzip
LZMA_PATH := $(CURDIR)/bin/lzma
ENC_TU_PATH := $(CURDIR)/bin/enc_ta/enc_ta.sh
AES_SCK_PATH := $(CURDIR)/../aes_sck_flash.bin
AES_VENDOR_ID_PATH := $(CURDIR)/../aes_vendor_id.bin
AES_MODULE_ID_PATH := $(CURDIR)/../aes_module_id.bin
AES_COMMON_TEST := $(CURDIR)/../aes_common_test.bin
ifeq ($(chip_rev), )
    CHIP_REV := 1
else
    CHIP_REV := $(chip_rev)
endif

ifeq ($(vmx), )
    VMX := n
else
    VMX := $(vmx)
endif

VMX_ULTRA_BUILD_OTA := $(vmx_ultra_build_ota)

#for android O supporting 1295 request
ifeq ($(ANDROID_IMGS), y)
    ANDROID_BRANCH = $(shell grep CONFIG_MANIFEST_BRANCH ../../.build_config | awk '{print $$2}')
	ifeq ($(findstring android-8, $(ANDROID_BRANCH)), android-8)
        ANDROID_BRANCH = android-8
	endif
	ifeq ($(findstring android-9, $(ANDROID_BRANCH)), android-9)
        ANDROID_BRANCH = android-9
	endif
endif

ifneq ($(NAS_IMGS), y)
	ifeq ($(ANDROID_IMGS), y)
        ANDROID_FILES := $(LAYOUT).uImage$(F_EXT) android.root.$(LAYOUT).cpio.gz_pad.img rescue.root.$(LAYOUT).cpio.gz_pad.img
	else
        ANDROID_FILES := $(LAYOUT).uImage$(F_EXT) rescue.root.$(LAYOUT).cpio.gz_pad.img
	endif
else
    ANDROID_FILES := $(LAYOUT).uImage$(F_EXT) rescue.root.$(LAYOUT).cpio.gz_pad.img
endif
ifeq ($(ANDROID_BRANCH), android-9)
    ANDROID_FILES := bootimg.bin recoveryimg.bin
endif

ifeq ($(CHIP_REV), 1)
AUDIO_FILE := bluecore.audio.enc.A00
else
AUDIO_FILE := bluecore.audio.enc.A01
endif

ifeq ($(HYPERVISOR), y)
    AUDIO_FILE := bluecore.audio
    AUDIO_FILE2 := bluecore.audio2
endif

ifeq ($(vmx), y)
ifeq ($(VMX_TYPE), ultra)
    AUDIO_FILE := bluecore.audio
    AUDIO_FILE2 := bluecore.audio2
endif
endif

DTB_FILES := android.$(LAYOUT).dtb$(F_EXT) rescue.$(LAYOUT).dtb$(F_EXT)
TEE_FILES := tee.bin bl31.bin

#############################

IMGFILE_PATH = $(CURDIR)/../$(IMGFILE_NAME)
IMGFILE_AP_PATH = $(CURDIR)/../$(PROJECT_NAME).$(LAYOUT).ap.img
EFUSE_FW_FILE = efuse_programmer.bin
EFUSE_FW_FILE_PATH = $(CURDIR)/../$(EFUSE_FW_FILE)
SECURE_FW_KEY_FILE = $(CURDIR)/../aes_128bit_key.bin.enc
SECURE_TEE_KEY_FILE = $(CURDIR)/../aes_128bit_key_2.bin.enc
SECURE_KEY_FILE = $(CURDIR)/../aes_128bit_key.bin
SECURE_KEY1_FILE = $(CURDIR)/../aes_128bit_key_1.bin
SECURE_KEY2_FILE = $(CURDIR)/../aes_128bit_key_2.bin
SECURE_KEY3_FILE = $(CURDIR)/../aes_128bit_key_3.bin
SECURE_KEY_SEED_FILE = $(CURDIR)/../aes_128bit_seed.bin
SECURE_KEY_FILE_REV = $(CURDIR)/../aes_128bit_key_rev.bin
SECURE_KEY_SEED_FILE_REV = $(CURDIR)/../aes_128bit_seed_rev.bin
RSA_PRIVATE_KEY = $(CURDIR)/../rsa_key_2048.pem
RSA_PRIVATE_KEY_REV = $(CURDIR)/../rsa_key_2048.pem.bin.rev
RSA_FW_PRIVATE_KEY = $(CURDIR)/../rsa_key_2048.fw.pem
RSA_TEE_PRIVATE_KEY = $(CURDIR)/../rsa_key_2048.tee.pem
RSA_LIB_PRIVATE_KEY = $(CURDIR)/../rsa_lib_2048.pem
RSA_LIB_PRIVATE_OTP_KEY = $(CURDIR)/../rsa_lib_otp_2048.pem
RSA_LIB_PUB_KEY = packages/$(TARGET)/system/vendor/lib/mediadrm/rsa_lib_2048.pub
EFUSE_PROGRAMMER_FILE = efuse_programmer.complete.enc
EFUSE_PROGRAMMER_FILE_PATH = $(CURDIR)/../$(EFUSE_PROGRAMMER_FILE)
EFUSE_VERIFY_FILE = efuse_verify.bin
EFUSE_VERIFY_FILE_PATH = $(CURDIR)/../$(EFUSE_VERIFY_FILE)

RPMB_FILE=rpmb_programmer.bin
RPMB_FILE_PATH=$(CURDIR)/../$(RPMB_FILE)

# VMX FILE DEFINITION
vmx_test_mode ?= 0
# 0: Rescue, 1: Normal, 2: Both
vmx_install_mode ?= 1
VMX_RSA_EMBED_BL_PRIVATE_KEY = $(CURDIR)/../vmx_rsa_key_2048.embed_bl.pem
VMX_AES_KEY = $(CURDIR)/../vmx_aes_128bit_key.bin
VMX_AES_KEY_KA = $(CURDIR)/../aes_128bit_ka.bin
VMX_AES_KEY_KC = $(CURDIR)/../aes_128bit_kc.bin
VMX_AES_KEY_KH = $(CURDIR)/../aes_128bit_kh.bin
VMX_AES_KEY_KX = $(CURDIR)/../aes_128bit_kx.bin
# version and market id
RESCUE_VERSION ?= 0
RESCUE_VERSION_BIN = rescue_version.bin
NORMAL_VERSION ?= 0
NORMAL_VERSION_BIN = normal_version.bin
TRUST_VERSION ?= 0
TRUST_VERSION_BIN = trust_version.bin
MARKET_ID ?= 0
MARKET_ID_BIN = market_id.bin
GEN_MARKET_ID = $(CURDIR)/bin/gen_market_id.pl
GEN_IMAGE_HEADER = $(CURDIR)/bin/gen_image_header
CREATE_SIGNATURE = $(CURDIR)/bin/create_signature.sh
GEN_FW_HEADER = $(CURDIR)/bin/gen_fw_header.pl
GEN_TRUST_FW_TABLE = $(CURDIR)/bin/gen_trust_fw_table.pl
TRUST_FW_COFIG = $(TMP)/pkgfile/trust_fw_config.txt
FW_HEADER_MAGIC_WORD = 0xAABBCCDD

#---------------------------------------------------------------------
#$(call hwrsa-sign, rsa_key_text, clear_data, enc_data)
hwrsa-sign =									\
        $(OPENSSL) rsa -text -in $(1) -out $(1).text;				\
        $(OPENSSL) rsautl -inkey $(1) -sign -in $(2) -out $(TMP_RSA_OUT);	\
        $(GEN_RSA_PATTERN) --key $(1).text --msg $(TMP_RSA_OUT) --binary;	\
        cat $(REAL_RSA_OUT) $(RRMODN) $(NP_INV32) > $(3)

hwrsa-sign64 =									\
        $(OPENSSL) rsa -text -in $(1) -out $(1).text;				\
        $(OPENSSL) rsautl -inkey $(1) -sign -in $(2) -out $(TMP_RSA_OUT);	\
        $(GEN_RSA_PATTERN64) --key $(1).text --msg $(TMP_RSA_OUT) --binary;	\
        cat $(REAL_RSA_OUT) $(RRMODN) $(NP_INV32) > $(3)

#Thor hwrsa doesn't require r^2 mod n and np_inv
hwrsa-sign-npinv64 =                                                                                          \
    $(OPENSSL) rsa -text -in $(1) -out $(1).text;                                           \
	$(OPENSSL) rsautl -inkey $(1) -sign -in $(2) -out $(TMP_RSA_OUT);			\
	$(GEN_RSA_PATTERN64) --key $(1).text --msg $(TMP_RSA_OUT) --binary;      \
	cat $(REAL_RSA_OUT) > $(3)
	#cat $(REAL_RSA_OUT) $(RRMODN) $(NP_INV32) > $(3)

###############

#$(call vmx-sign, file-dir, file-to-sign, signature-file, signed-file, rsa-key-file)
vmx-sign = \
	$(CREATE_SIGNATURE) `stat -c %s $(1)/$(2)` `stat -c %s $(1)/$(2)` $(2) $(3) $(4) $(5) 0 0


ifeq ($(offline_gen), y)
ifeq ($(wildcard installer_x86/setting.txt),)
$(error installer_x86/setting.txt does not exist)
endif
endif

ifeq ($(wildcard gen_binary/gen_binary_tool),)
$(error gen_binary/gen_binary_tool does not exist)
endif

ifeq ($(wildcard packages/$(TARGET)/System.map.audio),)
$(error packages/$(TARGET)/System.map.audio does not exist)
endif

#AUDIOADDR=0x$(shell grep -w _osboot packages/$(TARGET)/System.map.audio | awk -F' ' '{print $$1}')
AUDIOADDR?=0x0F900000
#LINUXADDR=0x$(shell grep -w stext packages/$(TARGET)/System.map | awk -F' ' '{print $$1}')
ifeq ($(NAS_IMGS), y)
  ifeq ($(HYPERVISOR), y)
  LINUXADDR=0x04000000
  else
  LINUXADDR=0x03000000
  endif
else
LINUXADDR=0x03000000
endif
KERNELDT_ADDR=0x02100000
RESCUEDT_ADDR=0x02140000
ifeq ($(vmx), y)
    ifeq ($(VMX_TYPE), ultra)
        KERNELROOTFSADDR=0x4BB00000
    else
        KERNELROOTFSADDR=0x3F000000
    endif
    BL31ADDR=0x10140000
else
    KERNELROOTFSADDR=0x02200000
    BL31ADDR=0x10120000
endif
RESCUEROOTFSADDR=0x30000000
TEEADDR=0x10200000
XENADDR=0x03000000
BOOTIMAGEDDR=0x20000000
RESCUEIMAGEDDR=0x23200000
ifeq ($(VMX_TYPE), ultra)
    LK_ADDR=0x00030000
else
    LK_ADDR=0x00020000
endif
RESCUE_AREA_ADDR=0x54000000
NORMAL_AREA_ADDR=0x54000000
TRUST_AREA_ADDR=0x54000000
ifeq ($(genAll), y)
    FLASH_SIZE= 8gb 16gb
else
    FLASH_SIZE= $(layout_size)
endif
#$(shell $(FDTGET_PATH) -t x ./packages/$(TARGET)/android.$(LAYOUT).dtb /fb reg | sed -e 's/\s.*//g' > $(TMP)/bootfile_image_addr)  # get fb address from dtb
TMP_BOOTFILE_IMAGE_ADDR=
ifeq ($(TMP_BOOTFILE_IMAGE_ADDR),)  # empty
BOOTFILE_IMAGE_ADDR=0x1e800000  # If nothing we can get from dtb, use this default value. 
else
BOOTFILE_IMAGE_ADDR=0x$(TMP_BOOTFILE_IMAGE_ADDR)
endif


############################

.PHONY: all
ifeq ($(only_install_factory), 1)
all: gen_config
else ifeq ($(only_install_bootcode), 1)
all: gen_config
else
all: gen_config prepare_file secure_case enableVMX
#### gen package
	$(QUIET) if [ '$(PKG_TYPE)' = 'TAR' ]; then \
		cd tmp/pkgfile/ && tar cvf $(IMGFILE_PATH) *; \
	fi
	
	$(QUIET) if [ '$(NAS_IMGS)' = 'y' ]; then \
		echo Original image size is `ls -lG $(IMGFILE_PATH) | awk -F' ' '{print $$4}'` && \
		if [ '$(hash_imgfile)' = 1 ]; then \
			if [ '$(SECURE_BOOT)' = y ]; then \
				dd if=/dev/zero  bs=1 count=`expr \( 4096000000 - \`ls -lG $(IMGFILE_PATH) | awk -F' ' '{print $$4}'\` - 256 \) % 4096` >> $(IMGFILE_PATH); \
				$(RTSSL_PATH) dgst -mars_sha1 -a -i $(IMGFILE_PATH) -sign -rsa -k $(RSA_PRIVATE_KEY); \
			else \
				dd if=/dev/zero  bs=1 count=`expr \( 4096000000 - \`ls -lG $(IMGFILE_PATH) | awk -F' ' '{print $$4}'\` - 20 \) % 4096` >> $(IMGFILE_PATH); \
				$(RTSSL_PATH) dgst -mars_sha1 -a -i $(IMGFILE_PATH) -sign -aes_128_ecb -k 0; \
			fi; \
		else \
			dd if=/dev/zero  bs=1 count=`expr \( 4096000000 - \`ls -lG $(IMGFILE_PATH) | awk -F' ' '{print $$4}'\` \) % 4096` >> $(IMGFILE_PATH); \
		fi; \
	fi
	$(QUIET) if [ '$(SECURE_BOOT)' = y ] && [ '$(efuse_key)' = '1' ] && [ '$(VMX)' = n ]; then \
		cd tmp/; \
		cp $(SECURE_KEY_FILE) pkgfile/; \
		cd pkgfile/; \
		tar rvf $(IMGFILE_PATH) aes_128bit_*; \
	fi;
#### pc_simulate for MP tool
	$(QUIET) if [ '$(offline_gen)' = 'y' ]; then \
		echo "offline gen. start....."; \
		rm -rf installer_x86/tmp; sync; \
		mkdir installer_x86/tmp; \
		chmod 775 installer_x86/tmp; \
		if [ '$(LAYOUT)' = 'emmc' ]; then \
			touch installer_x86/tmp/mmcblk0; \
			chmod 777 installer_x86/tmp/mmcblk0; \
		elif [ '$(LAYOUT)' = 'sata' ]; then \
			touch installer_x86/tmp/sataa0; \
			chmod 777 installer_x86/tmp/sataa0; \
		else \
			touch installer_x86/tmp/mtdblock0 installer_x86/tmp/mtd0; \
			chmod 777 installer_x86/tmp/mtdblock0 installer_x86/tmp/mtd0; \
		fi; \
		cat installer_x86/setting.txt|grep CONFIG_FLASH_PARTNAME >> tmp/pkgfile/config.txt; \
		if [ '$(NAS_IMGS)' = 'y' ]; then \
			cd installer_x86;./install_a.pc.nas ../../install.img $(FLASH_SIZE) $(PACKAGES) > /dev/null; \
		elif [ '$(PURE_LINUX_IMGS)' = 'y' ]; then \
			cd installer_x86;./install_a.pc.linux ../../install.img $(FLASH_SIZE) $(PACKAGES) > /dev/null; \
		else \
			if [ '$(VMX)' = 'y' ]; then \
				if [ '$(VMX_TYPE)' = 'ultra' ]; then \
					if [ '$(vmx_install_mode)' = 0 ]; then \
						if [ '$(SECURE_BOOT)' = 'y' ]; then \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/normal_boot_area.bin.aes; \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/rescue_boot_area.bin.aes; \
						else \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/normal_boot_area.bin; \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/rescue_boot_area.bin; \
						fi; \
					elif [ '$(vmx_install_mode)' = 1 ]; then \
						if [ '$(SECURE_BOOT)' = 'y' ]; then \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/rescue_boot_area.bin.aes; \
						else \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/rescue_boot_area.bin; \
						fi; \
						tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/trust_boot_area.bin.aes; \
					elif [ '$(vmx_install_mode)' = 2 ]; then \
						if [ '$(SECURE_BOOT)' = 'y' ]; then \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/normal_boot_area.bin.aes; \
						else \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/normal_boot_area.bin; \
						fi; \
						tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/trust_boot_area.bin.aes; \
					elif [ '$(vmx_install_mode)' = 3 ]; then \
						if [ '$(SECURE_BOOT)' = 'y' ]; then \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/rescue_boot_area.bin.aes; \
						else \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/rescue_boot_area.bin; \
						fi; \
					elif [ '$(vmx_install_mode)' = 4 ]; then \
						if [ '$(SECURE_BOOT)' = 'y' ]; then \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/normal_boot_area.bin.aes; \
						else \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/normal_boot_area.bin; \
						fi; \
					elif [ '$(vmx_install_mode)' = 5 ]; then \
						tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/trust_boot_area.bin.aes; \
					fi; \
				else \
					if [ '$(vmx_install_mode)' = 0 ]; then \
						if [ '$(SECURE_BOOT)' = 'y' ]; then \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/normal_boot_area.bin.aes; \
						else \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/normal_boot_area.bin; \
						fi; \
					elif [ '$(vmx_install_mode)' = 1 ]; then \
						if [ '$(SECURE_BOOT)' = 'y' ]; then \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/rescue_boot_area.bin.aes; \
						else \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/rescue_boot_area.bin; \
						fi; \
					fi; \
				fi; \
			fi; \
			if [ '$(VMX)' = 'y' ]; then \
				if [ '$(VMX_TYPE)' = 'ultra' ]; then \
					cd installer_x86;./install_a.pc.vmx.ultra ../../install.img $(FLASH_SIZE) $(PACKAGES) > /dev/null; \
				else \
					cd installer_x86;./install_a.pc.vmx ../../install.img $(FLASH_SIZE) $(PACKAGES) > /dev/null; \
				fi; \
			else \
				cd installer_x86;./install_a.pc ../../install.img $(FLASH_SIZE) $(PACKAGES) > /dev/null; \
			fi; \
		fi; \
		rm -rf $(PACKAGES);mkdir $(PACKAGES); \
		if [ '$(LAYOUT)' = 'nand' ]; then \
			cd $(PACKAGES); \
			../../bin/nf_profiler `cat $(CURDIR)/installer_x86/setting.txt|grep CONFIG_FLASH_PARTNAME | awk -F' ' '{print $$2}' | sed 's/\"//'`; \
			cp ../tmp/fw_tbl.bin .;cd ..;cp tmp/factory/layout.txt .; \
			echo "#define FW_PROFILE \" target=0 offset=0 size=`ls -lG $(CURDIR)/installer_x86/$(PACKAGES)/nf_profile.bin | awk -F' ' '{printf("%x",$$4)}'` type=bin name=$(PACKAGES)/nf_profile.bin nf_id=`cat $(CURDIR)/installer_x86/setting.txt|grep CONFIG_FLASH_PARTNAME | awk -F' ' '{print $$2}' | sed 's/\"//'` \"" >> layout.txt; \
			tar rvf $(IMGFILE_PATH) layout.txt $(PACKAGES)/fw_tbl.bin $(PACKAGES)/nf_profile.bin; \
		fi; \
		if [ '$(LAYOUT)' = 'emmc' ] || [ '$(LAYOUT)' = 'sata' ]; then \
			rm -f layout.txt;cp tmp/factory/layout.txt .; \
			cp tmp/fw_tbl.bin ./$(PACKAGES); \
			if [ -f tmp/mbr_00.bin ]; then cp tmp/mbr*.bin ./$(PACKAGES); \
			elif [ -f tmp/primary.gpt ]; then cp tmp/*.gpt ./$(PACKAGES); \
			else  echo "cannot find partition table" ; fi; \
			if [ '$(rpmb_fw)' = 1 ]; then \
				cp $(RPMB_FILE_PATH) ./$(PACKAGES); \
				echo "We find RPMB fw! (rpmb_programmer.bin)"; \
				echo "#define FW_RPMB \" target=0x01500000 offset=0 size=`ls -lG $(CURDIR)/installer_x86/$(PACKAGES)/$(RPMB_FILE) | awk -F' ' '{printf("%x",     $$4)}'` type=bin name=$(PACKAGES)/$(RPMB_FILE) \"" >> layout.txt; \
				tar rvf $(IMGFILE_PATH) layout.txt $(PACKAGES)/fw_tbl.bin $(PACKAGES)/$(RPMB_FILE); \
				if [ -f $(PACKAGES)/mbr_00.bin ]; then tar rvf $(IMGFILE_PATH) $(PACKAGES)/mbr*.bin; fi; \
				if [ -f $(PACKAGES)/primary.gpt ]; then tar rvf $(IMGFILE_PATH) $(PACKAGES)/*.gpt; fi; \
			else \
				if [ -f $(PACKAGES)/mbr_00.bin ]; then tar rvf $(IMGFILE_PATH) $(PACKAGES)/mbr*.bin; fi; \
				if [ -f $(PACKAGES)/primary.gpt ]; then tar rvf $(IMGFILE_PATH) $(PACKAGES)/*.gpt; fi; \
				tar rvf $(IMGFILE_PATH) layout.txt $(PACKAGES)/fw_tbl.bin ; \
			fi; \
			if [ '$(VMX)' = y ]; then \
				if [ '$(VMX_TYPE)' = 'ultra' ]; then \
					rm -rf vmx_tmp; \
					mkdir vmx_tmp; \
					tar xf $(IMGFILE_PATH) -C vmx_tmp; \
					cd vmx_tmp/$(PACKAGES); \
					dd if=/dev/zero of=./fw_tbl.bin.padding \
						bs=`expr 16 \* 1024 - \`stat -c %s $(CURDIR)/installer_x86/vmx_tmp/$(PACKAGES)/fw_tbl.bin\`` count=1; \
					dd if=/dev/zero of=./trust_fw_tbl.bin.padding \
						bs=`expr 1 \* 1024 - \`stat -c %s $(CURDIR)/installer_x86/vmx_tmp/$(PACKAGES)/trust_fw_tbl.bin\`` count=1; \
					cat fw_tbl.bin fw_tbl.bin.padding > fw_tbl.bin.final; \
					cat trust_fw_tbl.bin trust_fw_tbl.bin.padding > trust_fw_tbl.bin.final; \
					cp fw_tbl.bin.final rescue_fw_tbl.bin.final; \
					\
					if [ '$(SECURE_BOOT)' = 'y' ]; then \
						if [ '$(vmx_install_mode)' = 0 ]; then \
							cat trust_fw_tbl.bin.final trust_boot_area.bin.aes > trust_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) trust_boot_area_to_sign.bin trust_boot_area_to_sign_padding.bin trust_boot_area_to_sign_digest.bin; \
							cat trust_boot_area_to_sign.bin trust_boot_area_to_sign_padding.bin > trust_boot_area_to_sign_final.bin; \
							mv trust_boot_area_to_sign_final.bin trust_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s trust_boot_area_to_sign.bin\``" trust_fw_header.bin || exit 1; \
						elif [ '$(vmx_install_mode)' = 1 ]; then \
							cat fw_tbl.bin.final normal_boot_area.bin.aes > normal_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) normal_boot_area_to_sign.bin normal_boot_area_to_sign_padding.bin normal_boot_area_to_sign_digest.bin; \
							cat normal_boot_area_to_sign.bin normal_boot_area_to_sign_padding.bin > normal_boot_area_to_sign_final.bin; \
							mv normal_boot_area_to_sign_final.bin normal_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s normal_boot_area_to_sign.bin\``" normal_fw_header.bin || exit 1; \
						elif [ '$(vmx_install_mode)' = 2 ]; then \
							cat rescue_fw_tbl.bin.final rescue_boot_area.bin.aes > rescue_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) rescue_boot_area_to_sign.bin rescue_boot_area_to_sign_padding.bin rescue_boot_area_to_sign_digest.bin; \
							cat rescue_boot_area_to_sign.bin rescue_boot_area_to_sign_padding.bin > rescue_boot_area_to_sign_final.bin; \
							mv rescue_boot_area_to_sign_final.bin rescue_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s rescue_boot_area_to_sign.bin\``" rescue_fw_header.bin || exit 1; \
						elif [ '$(vmx_install_mode)' = 3 ]; then \
							cat trust_fw_tbl.bin.final trust_boot_area.bin.aes > trust_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) trust_boot_area_to_sign.bin trust_boot_area_to_sign_padding.bin trust_boot_area_to_sign_digest.bin; \
							cat trust_boot_area_to_sign.bin trust_boot_area_to_sign_padding.bin > trust_boot_area_to_sign_final.bin; \
							mv trust_boot_area_to_sign_final.bin trust_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s trust_boot_area_to_sign.bin\``" trust_fw_header.bin || exit 1; \
							cat fw_tbl.bin.final normal_boot_area.bin.aes > normal_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) normal_boot_area_to_sign.bin normal_boot_area_to_sign_padding.bin normal_boot_area_to_sign_digest.bin; \
							cat normal_boot_area_to_sign.bin normal_boot_area_to_sign_padding.bin > normal_boot_area_to_sign_final.bin; \
							mv normal_boot_area_to_sign_final.bin normal_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s normal_boot_area_to_sign.bin\``" normal_fw_header.bin || exit 1; \
						elif [ '$(vmx_install_mode)' = 4 ]; then \
							cat trust_fw_tbl.bin.final trust_boot_area.bin.aes > trust_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) trust_boot_area_to_sign.bin trust_boot_area_to_sign_padding.bin trust_boot_area_to_sign_digest.bin; \
							cat trust_boot_area_to_sign.bin trust_boot_area_to_sign_padding.bin > trust_boot_area_to_sign_final.bin; \
							mv trust_boot_area_to_sign_final.bin trust_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s trust_boot_area_to_sign.bin\``" trust_fw_header.bin || exit 1; \
							cat rescue_fw_tbl.bin.final rescue_boot_area.bin.aes > rescue_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) rescue_boot_area_to_sign.bin rescue_boot_area_to_sign_padding.bin rescue_boot_area_to_sign_digest.bin; \
							cat rescue_boot_area_to_sign.bin rescue_boot_area_to_sign_padding.bin > rescue_boot_area_to_sign_final.bin; \
							mv rescue_boot_area_to_sign_final.bin rescue_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s rescue_boot_area_to_sign.bin\``" rescue_fw_header.bin || exit 1; \
						elif [ '$(vmx_install_mode)' = 5 ]; then \
							cat fw_tbl.bin.final normal_boot_area.bin.aes > normal_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) normal_boot_area_to_sign.bin normal_boot_area_to_sign_padding.bin normal_boot_area_to_sign_digest.bin; \
							cat normal_boot_area_to_sign.bin normal_boot_area_to_sign_padding.bin > normal_boot_area_to_sign_final.bin; \
							mv normal_boot_area_to_sign_final.bin normal_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s normal_boot_area_to_sign.bin\``" normal_fw_header.bin || exit 1; \
							cat rescue_fw_tbl.bin.final rescue_boot_area.bin.aes > rescue_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) rescue_boot_area_to_sign.bin rescue_boot_area_to_sign_padding.bin rescue_boot_area_to_sign_digest.bin; \
							cat rescue_boot_area_to_sign.bin rescue_boot_area_to_sign_padding.bin > rescue_boot_area_to_sign_final.bin; \
							mv rescue_boot_area_to_sign_final.bin rescue_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s rescue_boot_area_to_sign.bin\``" rescue_fw_header.bin || exit 1; \
						else \
							cat trust_fw_tbl.bin.final trust_boot_area.bin.aes > trust_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) trust_boot_area_to_sign.bin trust_boot_area_to_sign_padding.bin trust_boot_area_to_sign_digest.bin; \
							cat trust_boot_area_to_sign.bin trust_boot_area_to_sign_padding.bin > trust_boot_area_to_sign_final.bin; \
							mv trust_boot_area_to_sign_final.bin trust_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s trust_boot_area_to_sign.bin\``" trust_fw_header.bin || exit 1; \
							cat fw_tbl.bin.final normal_boot_area.bin.aes > normal_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) normal_boot_area_to_sign.bin normal_boot_area_to_sign_padding.bin normal_boot_area_to_sign_digest.bin; \
							cat normal_boot_area_to_sign.bin normal_boot_area_to_sign_padding.bin > normal_boot_area_to_sign_final.bin; \
							mv normal_boot_area_to_sign_final.bin normal_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s normal_boot_area_to_sign.bin\``" normal_fw_header.bin || exit 1; \
							cat rescue_fw_tbl.bin.final rescue_boot_area.bin.aes > rescue_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) rescue_boot_area_to_sign.bin rescue_boot_area_to_sign_padding.bin rescue_boot_area_to_sign_digest.bin; \
							cat rescue_boot_area_to_sign.bin rescue_boot_area_to_sign_padding.bin > rescue_boot_area_to_sign_final.bin; \
							mv rescue_boot_area_to_sign_final.bin rescue_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s rescue_boot_area_to_sign.bin\``" rescue_fw_header.bin || exit 1; \
						fi; \
					else \
						if [ '$(vmx_install_mode)' = 0 ]; then \
							cat trust_fw_tbl.bin.final trust_boot_area.bin.aes > trust_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) trust_boot_area_to_sign.bin trust_boot_area_to_sign_padding.bin trust_boot_area_to_sign_digest.bin; \
							cat trust_boot_area_to_sign.bin trust_boot_area_to_sign_padding.bin > trust_boot_area_to_sign_final.bin; \
							mv trust_boot_area_to_sign_final.bin trust_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s trust_boot_area_to_sign.bin\``" trust_fw_header.bin || exit 1; \
						elif [ '$(vmx_install_mode)' = 1 ]; then \
							cat fw_tbl.bin.final normal_boot_area.bin > normal_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) normal_boot_area_to_sign.bin normal_boot_area_to_sign_padding.bin normal_boot_area_to_sign_digest.bin; \
							cat normal_boot_area_to_sign.bin normal_boot_area_to_sign_padding.bin > normal_boot_area_to_sign_final.bin; \
							mv normal_boot_area_to_sign_final.bin normal_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x0 "0x`printf '%X' \`stat -c %s normal_boot_area_to_sign.bin\``" normal_fw_header.bin || exit 1; \
						elif [ '$(vmx_install_mode)' = 2 ]; then \
							cat rescue_fw_tbl.bin.final rescue_boot_area.bin > rescue_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) rescue_boot_area_to_sign.bin rescue_boot_area_to_sign_padding.bin rescue_boot_area_to_sign_digest.bin; \
							cat rescue_boot_area_to_sign.bin rescue_boot_area_to_sign_padding.bin > rescue_boot_area_to_sign_final.bin; \
							mv rescue_boot_area_to_sign_final.bin rescue_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s rescue_boot_area_to_sign.bin\``" rescue_fw_header.bin || exit 1; \
						elif [ '$(vmx_install_mode)' = 3 ]; then \
							cat trust_fw_tbl.bin.final trust_boot_area.bin.aes > trust_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) trust_boot_area_to_sign.bin trust_boot_area_to_sign_padding.bin trust_boot_area_to_sign_digest.bin; \
							cat trust_boot_area_to_sign.bin trust_boot_area_to_sign_padding.bin > trust_boot_area_to_sign_final.bin; \
							mv trust_boot_area_to_sign_final.bin trust_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s trust_boot_area_to_sign.bin\``" trust_fw_header.bin || exit 1; \
							cat fw_tbl.bin.final normal_boot_area.bin > normal_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) normal_boot_area_to_sign.bin normal_boot_area_to_sign_padding.bin normal_boot_area_to_sign_digest.bin; \
							cat normal_boot_area_to_sign.bin normal_boot_area_to_sign_padding.bin > normal_boot_area_to_sign_final.bin; \
							mv normal_boot_area_to_sign_final.bin normal_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x0 "0x`printf '%X' \`stat -c %s normal_boot_area_to_sign.bin\``" normal_fw_header.bin || exit 1; \
						elif [ '$(vmx_install_mode)' = 4 ]; then \
							cat trust_fw_tbl.bin.final trust_boot_area.bin.aes > trust_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) trust_boot_area_to_sign.bin trust_boot_area_to_sign_padding.bin trust_boot_area_to_sign_digest.bin; \
							cat trust_boot_area_to_sign.bin trust_boot_area_to_sign_padding.bin > trust_boot_area_to_sign_final.bin; \
							mv trust_boot_area_to_sign_final.bin trust_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s trust_boot_area_to_sign.bin\``" trust_fw_header.bin || exit 1; \
							cat rescue_fw_tbl.bin.final rescue_boot_area.bin > rescue_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) rescue_boot_area_to_sign.bin rescue_boot_area_to_sign_padding.bin rescue_boot_area_to_sign_digest.bin; \
							cat rescue_boot_area_to_sign.bin rescue_boot_area_to_sign_padding.bin > rescue_boot_area_to_sign_final.bin; \
							mv rescue_boot_area_to_sign_final.bin rescue_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s rescue_boot_area_to_sign.bin\``" rescue_fw_header.bin || exit 1; \
						elif [ '$(vmx_install_mode)' = 5 ]; then \
							cat fw_tbl.bin.final normal_boot_area.bin > normal_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) normal_boot_area_to_sign.bin normal_boot_area_to_sign_padding.bin normal_boot_area_to_sign_digest.bin; \
							cat normal_boot_area_to_sign.bin normal_boot_area_to_sign_padding.bin > normal_boot_area_to_sign_final.bin; \
							mv normal_boot_area_to_sign_final.bin normal_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x0 "0x`printf '%X' \`stat -c %s normal_boot_area_to_sign.bin\``" normal_fw_header.bin || exit 1; \
							cat rescue_fw_tbl.bin.final rescue_boot_area.bin > rescue_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) rescue_boot_area_to_sign.bin rescue_boot_area_to_sign_padding.bin rescue_boot_area_to_sign_digest.bin; \
							cat rescue_boot_area_to_sign.bin rescue_boot_area_to_sign_padding.bin > rescue_boot_area_to_sign_final.bin; \
							mv rescue_boot_area_to_sign_final.bin rescue_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s rescue_boot_area_to_sign.bin\``" rescue_fw_header.bin || exit 1; \
						else \
							cat trust_fw_tbl.bin.final trust_boot_area.bin.aes > trust_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) trust_boot_area_to_sign.bin trust_boot_area_to_sign_padding.bin trust_boot_area_to_sign_digest.bin; \
							cat trust_boot_area_to_sign.bin trust_boot_area_to_sign_padding.bin > trust_boot_area_to_sign_final.bin; \
							mv trust_boot_area_to_sign_final.bin trust_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s trust_boot_area_to_sign.bin\``" trust_fw_header.bin || exit 1; \
							cat fw_tbl.bin.final normal_boot_area.bin > normal_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) normal_boot_area_to_sign.bin normal_boot_area_to_sign_padding.bin normal_boot_area_to_sign_digest.bin; \
							cat normal_boot_area_to_sign.bin normal_boot_area_to_sign_padding.bin > normal_boot_area_to_sign_final.bin; \
							mv normal_boot_area_to_sign_final.bin normal_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s normal_boot_area_to_sign.bin\``" normal_fw_header.bin || exit 1; \
							cat rescue_fw_tbl.bin.final rescue_boot_area.bin > rescue_boot_area_to_sign.bin; \
							$(DO_SHA256_PATH) rescue_boot_area_to_sign.bin rescue_boot_area_to_sign_padding.bin rescue_boot_area_to_sign_digest.bin; \
							cat rescue_boot_area_to_sign.bin rescue_boot_area_to_sign_padding.bin > rescue_boot_area_to_sign_final.bin; \
							mv rescue_boot_area_to_sign_final.bin rescue_boot_area_to_sign.bin; \
							$(GEN_FW_HEADER) $(FW_HEADER_MAGIC_WORD) 0x1 "0x`printf '%X' \`stat -c %s rescue_boot_area_to_sign.bin\``" rescue_fw_header.bin || exit 1; \
						fi; \
					fi; \
					\
					[ -f $(CURDIR)/../rescue_boot_area.bin ] && rm $(CURDIR)/../rescue_boot_area.bin; \
					[ -f $(CURDIR)/../rescue_boot_area.bin.aes ] && rm $(CURDIR)/../rescue_boot_area.bin.aes; \
					[ -f $(CURDIR)/../normal_boot_area.bin ] && rm $(CURDIR)/../normal_boot_area.bin; \
					[ -f $(CURDIR)/../normal_boot_area.bin.aes ] && rm $(CURDIR)/../normal_boot_area.bin.aes; \
					[ -f $(CURDIR)/../trust_boot_area.bin ] && rm $(CURDIR)/../trust_boot_area.bin; \
					[ -f $(CURDIR)/../trust_boot_area.bin.aes ] && rm $(CURDIR)/../trust_boot_area.bin.aes; \
					if [ '$(vmx_install_mode)' = 0 ]; then \
						$(DO_SHA256_PATH) trust_fw_header.bin trust_fw_header_padding.bin trust_fw_header_digest.bin; \
						cat trust_fw_header.bin trust_fw_header_padding.bin > trust_fw_header_to_sign.bin; \
					elif [ '$(vmx_install_mode)' = 1 ]; then \
						$(DO_SHA256_PATH) normal_fw_header.bin normal_fw_header_padding.bin normal_fw_header_digest.bin; \
						cat normal_fw_header.bin normal_fw_header_padding.bin > normal_fw_header_to_sign.bin; \
					elif [ '$(vmx_install_mode)' = 2 ]; then \
						$(DO_SHA256_PATH) rescue_fw_header.bin rescue_fw_header_padding.bin rescue_fw_header_digest.bin; \
						cat rescue_fw_header.bin rescue_fw_header_padding.bin > rescue_fw_header_to_sign.bin; \
					elif [ '$(vmx_install_mode)' = 3 ]; then \
						$(DO_SHA256_PATH) trust_fw_header.bin trust_fw_header_padding.bin trust_fw_header_digest.bin; \
						cat trust_fw_header.bin trust_fw_header_padding.bin > trust_fw_header_to_sign.bin; \
						$(DO_SHA256_PATH) normal_fw_header.bin normal_fw_header_padding.bin normal_fw_header_digest.bin; \
						cat normal_fw_header.bin normal_fw_header_padding.bin > normal_fw_header_to_sign.bin; \
					elif [ '$(vmx_install_mode)' = 4 ]; then \
						$(DO_SHA256_PATH) trust_fw_header.bin trust_fw_header_padding.bin trust_fw_header_digest.bin; \
						cat trust_fw_header.bin trust_fw_header_padding.bin > trust_fw_header_to_sign.bin; \
						$(DO_SHA256_PATH) rescue_fw_header.bin rescue_fw_header_padding.bin rescue_fw_header_digest.bin; \
						cat rescue_fw_header.bin rescue_fw_header_padding.bin > rescue_fw_header_to_sign.bin; \
					elif [ '$(vmx_install_mode)' = 5 ]; then \
						$(DO_SHA256_PATH) normal_fw_header.bin normal_fw_header_padding.bin normal_fw_header_digest.bin; \
						cat normal_fw_header.bin normal_fw_header_padding.bin > normal_fw_header_to_sign.bin; \
						$(DO_SHA256_PATH) rescue_fw_header.bin rescue_fw_header_padding.bin rescue_fw_header_digest.bin; \
						cat rescue_fw_header.bin rescue_fw_header_padding.bin > rescue_fw_header_to_sign.bin; \
					else \
						$(DO_SHA256_PATH) trust_fw_header.bin trust_fw_header_padding.bin trust_fw_header_digest.bin; \
						cat trust_fw_header.bin trust_fw_header_padding.bin > trust_fw_header_to_sign.bin; \
						$(DO_SHA256_PATH) normal_fw_header.bin normal_fw_header_padding.bin normal_fw_header_digest.bin; \
						cat normal_fw_header.bin normal_fw_header_padding.bin > normal_fw_header_to_sign.bin; \
						$(DO_SHA256_PATH) rescue_fw_header.bin rescue_fw_header_padding.bin rescue_fw_header_digest.bin; \
						cat rescue_fw_header.bin rescue_fw_header_padding.bin > rescue_fw_header_to_sign.bin; \
					fi; \
					if [ -f rescue_boot_area_to_sign.bin ]; then \
						if [ '$(SECURE_BOOT)' = 'y' ]; then \
							$(call hwrsa-sign64, $(RSA_FW_PRIVATE_KEY), rescue_boot_area_to_sign_digest.bin, rescue_boot_area_to_sign_digest_enc.bin); \
							$(RTSSL_PATH) enc -e -aes_128_cbc -k `hexdump -e '8/1 "%02x"' $(AES_COMMON_TEST)` \
								-i rescue_boot_area_to_sign.bin -o rescue_boot_area.bin.aes; \
							$(call hwrsa-sign64, $(RSA_FW_PRIVATE_KEY), rescue_fw_header_digest.bin, rescue_fw_header_digest_enc.bin); \
							$(RTSSL_PATH) enc -e -aes_128_cbc -k `hexdump -e '8/1 "%02x"' $(AES_COMMON_TEST)` \
								-i rescue_fw_header_to_sign.bin -o rescue_fw_header.bin.aes; \
							cat rescue_fw_header.bin.aes rescue_fw_header_digest_enc.bin rescue_boot_area.bin.aes rescue_boot_area_to_sign_digest_enc.bin > rescue_boot_area.bin.aes.sig; \
							mv rescue_boot_area.bin.aes.sig rescue_boot_area.bin.aes; \
							cp rescue_boot_area.bin.aes $(CURDIR)/../; \
							cd ..; \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/rescue_boot_area.bin.aes; \
							tar rvf $(IMGFILE_PATH) $(PACKAGES)/rescue_boot_area.bin.aes; \
							cd $(PACKAGES); \
						else \
							dd if=/dev/zero of=./rescue.padding bs=520 count=1; \
							cat rescue_fw_header_to_sign.bin rescue.padding rescue_boot_area_to_sign.bin rescue.padding > rescue_boot_area.bin; \
							cp rescue_boot_area.bin $(CURDIR)/../; \
							rm rescue.padding; \
							cd ..; \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/rescue_boot_area.bin; \
							tar rvf $(IMGFILE_PATH) $(PACKAGES)/rescue_boot_area.bin; \
							cd $(PACKAGES); \
						fi; \
					fi; \
					if [ -f normal_boot_area_to_sign.bin ]; then \
						if [ '$(SECURE_BOOT)' = 'y' ]; then \
							$(call hwrsa-sign64, $(RSA_FW_PRIVATE_KEY), normal_boot_area_to_sign_digest.bin, normal_boot_area_to_sign_digest_enc.bin); \
							$(RTSSL_PATH) enc -e -aes_128_cbc -k `hexdump -e '8/1 "%02x"' $(AES_COMMON_TEST)` \
								-i normal_boot_area_to_sign.bin -o normal_boot_area.bin.aes; \
							$(call hwrsa-sign64, $(RSA_FW_PRIVATE_KEY), normal_fw_header_digest.bin, normal_fw_header_digest_enc.bin); \
							$(RTSSL_PATH) enc -e -aes_128_cbc -k `hexdump -e '8/1 "%02x"' $(AES_COMMON_TEST)` \
								-i normal_fw_header_to_sign.bin -o normal_fw_header.bin.aes; \
							cat normal_fw_header.bin.aes normal_fw_header_digest_enc.bin normal_boot_area.bin.aes normal_boot_area_to_sign_digest_enc.bin > normal_boot_area.bin.aes.sig; \
							mv normal_boot_area.bin.aes.sig normal_boot_area.bin.aes; \
							cp normal_boot_area.bin.aes $(CURDIR)/../; \
							cd ..; \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/normal_boot_area.bin.aes; \
							tar rvf $(IMGFILE_PATH) $(PACKAGES)/normal_boot_area.bin.aes; \
							cd $(PACKAGES); \
						else \
							dd if=/dev/zero of=./normal.padding bs=520 count=1; \
							cat normal_fw_header_to_sign.bin normal.padding normal_boot_area_to_sign.bin normal.padding > normal_boot_area.bin; \
							cp normal_boot_area.bin $(CURDIR)/../; \
							rm normal.padding; \
							cd ..; \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/normal_boot_area.bin; \
							tar rvf $(IMGFILE_PATH) $(PACKAGES)/normal_boot_area.bin; \
							cd $(PACKAGES); \
						fi; \
					fi; \
					if [ -f trust_boot_area_to_sign.bin ]; then \
						$(call hwrsa-sign64, $(RSA_TEE_PRIVATE_KEY), trust_boot_area_to_sign_digest.bin, trust_boot_area_to_sign_digest_enc.bin); \
						$(OBFUSE_H_CBC) $(RTSSL_PATH) 97 $(AES_MODULE_ID_PATH) $(AES_MODULE_ID_PATH) $(AES_SCK_PATH) $(AES_VENDOR_ID_PATH) trust_boot_area_to_sign.bin trust_boot_area.bin.aes; \
						$(call hwrsa-sign64, $(RSA_TEE_PRIVATE_KEY), trust_fw_header_digest.bin, trust_fw_header_digest_enc.bin); \
						$(OBFUSE_H_CBC) $(RTSSL_PATH) 97 $(AES_MODULE_ID_PATH) $(AES_MODULE_ID_PATH) $(AES_SCK_PATH) $(AES_VENDOR_ID_PATH) trust_fw_header_to_sign.bin trust_fw_header.bin.aes; \
						cat trust_fw_header.bin.aes trust_fw_header_digest_enc.bin trust_boot_area.bin.aes trust_boot_area_to_sign_digest_enc.bin > trust_boot_area.bin.aes.sig; \
						mv trust_boot_area.bin.aes.sig trust_boot_area.bin.aes; \
						cp trust_boot_area.bin.aes $(CURDIR)/../; \
						cd ..; \
						tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/trust_boot_area.bin.aes; \
						tar rvf $(IMGFILE_PATH) $(PACKAGES)/trust_boot_area.bin.aes; \
						cd $(PACKAGES); \
					fi; \
					if [ '$(SECURE_BOOT)' = 'y' ]; then \
						if [ -f trust_boot_area.bin.aes ]; then \
							echo "fw = trustArea1 $(PACKAGES)/trust_boot_area.bin.aes $(TRUST_AREA_ADDR)" \
								"0x`printf '%X' \`stat -c %s trust_boot_area.bin.aes\``" >> ../config.txt; \
							echo "fw = trustArea2 $(PACKAGES)/trust_boot_area.bin.aes $(TRUST_AREA_ADDR)" \
								"0x`printf '%X' \`stat -c %s trust_boot_area.bin.aes\``" >> ../config.txt; \
						fi ;\
						if [ -f normal_boot_area.bin.aes ]; then \
							echo "fw = normalArea $(PACKAGES)/normal_boot_area.bin.aes $(NORMAL_AREA_ADDR)" \
								"0x`printf '%X' \`stat -c %s normal_boot_area.bin.aes\``" >> ../config.txt; \
						fi ;\
						if [ -f rescue_boot_area.bin.aes ]; then \
							echo "fw = rescueArea $(PACKAGES)/rescue_boot_area.bin.aes $(RESCUE_AREA_ADDR)" \
								"0x`printf '%X' \`stat -c %s rescue_boot_area.bin.aes\``" >> ../config.txt; \
						fi; \
					else \
						if [ -f trust_boot_area.bin.aes ]; then \
							echo "fw = trustArea1 $(PACKAGES)/trust_boot_area.bin.aes $(TRUST_AREA_ADDR)" \
								"0x`printf '%X' \`stat -c %s trust_boot_area.bin.aes\``" >> ../config.txt; \
							echo "fw = trustArea2 $(PACKAGES)/trust_boot_area.bin.aes $(TRUST_AREA_ADDR)" \
								"0x`printf '%X' \`stat -c %s trust_boot_area.bin.aes\``" >> ../config.txt; \
						fi ;\
						if [ -f normal_boot_area.bin ]; then \
							echo "fw = normalArea $(PACKAGES)/normal_boot_area.bin $(NORMAL_AREA_ADDR)" \
								"0x`printf '%X' \`stat -c %s normal_boot_area.bin\``" >> ../config.txt; \
						fi ;\
						if [ -f rescue_boot_area.bin ]; then \
							echo "fw = rescueArea $(PACKAGES)/rescue_boot_area.bin $(RESCUE_AREA_ADDR)" \
								"0x`printf '%X' \`stat -c %s rescue_boot_area.bin\``" >> ../config.txt; \
						fi ;\
					fi ; \
					tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/fw_tbl.bin; \
					tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/trust_fw_tbl.bin; \
					tar --delete --file=$(IMGFILE_PATH) config.txt; \
					tar rvf $(IMGFILE_PATH) ../config.txt; \
					\
					if [ '$(VMX_ULTRA_BUILD_OTA)' = 'yes' ]; then \
						rm -f $(IMGFILE_PATH); \
						if [ -f trust_boot_area.bin.aes ]; then \
							tar rvf $(IMGFILE_PATH) trust_boot_area.bin.aes; \
						fi; \
						if [ -f normal_boot_area.bin.aes ]; then \
							tar rvf $(IMGFILE_PATH) normal_boot_area.bin.aes; \
						fi; \
						if [ -f rescue_boot_area.bin.aes ]; then \
							tar rvf $(IMGFILE_PATH) rescue_boot_area.bin.aes; \
						fi; \
						if [ -f normal_boot_area.bin ]; then \
							tar rvf $(IMGFILE_PATH) normal_boot_area.bin; \
						fi; \
						if [ -f rescue_boot_area.bin ]; then \
							tar rvf $(IMGFILE_PATH) rescue_boot_area.bin; \
						fi; \
					fi; \
					\
					cd ../../; \
				else \
					rm -rf vmx_tmp; \
					mkdir vmx_tmp; \
					tar xf $(IMGFILE_PATH) -C vmx_tmp; \
					cd vmx_tmp/$(PACKAGES); \
					dd if=/dev/zero of=./fw_tbl.bin.padding \
						bs=`expr 16 \* 1024 - \`stat -c %s $(CURDIR)/installer_x86/vmx_tmp/$(PACKAGES)/fw_tbl.bin\`` count=1; \
					cat fw_tbl.bin fw_tbl.bin.padding > fw_tbl.bin.final; \
					cp fw_tbl.bin.final rescue_fw_tbl.bin.final; \
					\
					if [ '$(SECURE_BOOT)' = 'y' ]; then \
						if [ '$(vmx_install_mode)' = 0 ]; then \
							cat rescue_fw_tbl.bin.final rescue_boot_area.bin.aes > rescue_boot_area_to_sign.bin; \
						elif [ '$(vmx_install_mode)' = 1 ]; then \
							cat fw_tbl.bin.final normal_boot_area.bin.aes > normal_boot_area_to_sign.bin; \
						else \
							cat rescue_fw_tbl.bin.final rescue_boot_area.bin.aes > rescue_boot_area_to_sign.bin; \
							cat fw_tbl.bin.final normal_boot_area.bin.aes > normal_boot_area_to_sign.bin; \
						fi; \
					else \
						if [ '$(vmx_install_mode)' = 0 ]; then \
							cat rescue_fw_tbl.bin.final rescue_boot_area.bin > rescue_boot_area_to_sign.bin; \
						elif [ '$(vmx_install_mode)' = 1 ]; then \
							cat fw_tbl.bin.final normal_boot_area.bin > normal_boot_area_to_sign.bin; \
						else \
							cat rescue_fw_tbl.bin.final rescue_boot_area.bin > rescue_boot_area_to_sign.bin; \
							cat fw_tbl.bin.final normal_boot_area.bin > normal_boot_area_to_sign.bin; \
						fi; \
					fi; \
					\
					[ -f $(CURDIR)/../rescue_boot_area.bin ] && rm $(CURDIR)/../rescue_boot_area.bin; \
					[ -f $(CURDIR)/../rescue_boot_area.bin.aes ] && rm $(CURDIR)/../rescue_boot_area.bin.aes; \
					[ -f $(CURDIR)/../normal_boot_area.bin ] && rm $(CURDIR)/../normal_boot_area.bin; \
					[ -f $(CURDIR)/../normal_boot_area.bin.aes ] && rm $(CURDIR)/../normal_boot_area.bin.aes; \
					if [ -f rescue_boot_area_to_sign.bin ]; then \
						if [ '$(SECURE_BOOT)' = 'y' ]; then \
							$(call vmx-sign,$(CURDIR)/installer_x86/vmx_tmp/$(PACKAGES),rescue_boot_area_to_sign.bin,rescue_boot_area_to_sign.bin.sig,rescue_boot_area_sign.bin,$(VMX_RSA_EMBED_BL_PRIVATE_KEY)) || exit 1; \
							$(RTSSL_PATH) enc -e -aes_128_cbc -k `hexdump -e '8/1 "%02x"' $(VMX_AES_KEY)` \
								-i rescue_boot_area_to_sign.bin -o rescue_boot_area.bin.aes; \
							cat rescue_boot_area.bin.aes rescue_boot_area_to_sign.bin.sig > rescue_boot_area.bin.aes.sig; \
							mv rescue_boot_area.bin.aes.sig rescue_boot_area.bin.aes; \
							cp rescue_boot_area.bin.aes $(CURDIR)/../; \
							cd ..; \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/rescue_boot_area.bin.aes; \
							tar rvf $(IMGFILE_PATH) $(PACKAGES)/rescue_boot_area.bin.aes; \
							cd $(PACKAGES); \
						else \
							$(call vmx-sign, $(CURDIR)/installer_x86/vmx_tmp/$(PACKAGES),rescue_boot_area_to_sign.bin,rescue_boot_area_to_sign.bin.sig,rescue_boot_area_sign.bin,null) || exit 1; \
							mv rescue_boot_area_sign.bin rescue_boot_area.bin.sig; \
							mv rescue_boot_area.bin.sig rescue_boot_area.bin; \
							cp rescue_boot_area.bin $(CURDIR)/../; \
							cd ..; \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/rescue_boot_area.bin; \
							tar rvf $(IMGFILE_PATH) $(PACKAGES)/rescue_boot_area.bin; \
							cd $(PACKAGES); \
						fi; \
					fi; \
					if [ -f normal_boot_area_to_sign.bin ]; then \
						if [ '$(SECURE_BOOT)' = 'y' ]; then \
							$(call vmx-sign,$(CURDIR)/installer_x86/vmx_tmp/$(PACKAGES),normal_boot_area_to_sign.bin,normal_boot_area_to_sign.bin.sig,normal_boot_area_sign.bin,$(VMX_RSA_EMBED_BL_PRIVATE_KEY)) || exit 1; \
							$(RTSSL_PATH) enc -e -aes_128_cbc -k `hexdump -e '8/1 "%02x"' $(VMX_AES_KEY)` \
								-i normal_boot_area_to_sign.bin -o normal_boot_area.bin.aes; \
							cat normal_boot_area.bin.aes normal_boot_area_to_sign.bin.sig > normal_boot_area.bin.aes.sig; \
							mv normal_boot_area.bin.aes.sig normal_boot_area.bin.aes; \
							cp normal_boot_area.bin.aes $(CURDIR)/../; \
							cd ..; \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/normal_boot_area.bin.aes; \
							tar rvf $(IMGFILE_PATH) $(PACKAGES)/normal_boot_area.bin.aes; \
							cd $(PACKAGES); \
						else \
							$(call vmx-sign, $(CURDIR)/installer_x86/vmx_tmp/$(PACKAGES),normal_boot_area_to_sign.bin,normal_boot_area_to_sign.bin.sig,normal_boot_area_sign.bin,null) || exit 1; \
							mv normal_boot_area_sign.bin normal_boot_area.bin.sig; \
							mv normal_boot_area.bin.sig normal_boot_area.bin; \
							cp normal_boot_area.bin $(CURDIR)/../; \
							cd ..; \
							tar --delete --file=$(IMGFILE_PATH) $(PACKAGES)/normal_boot_area.bin; \
							tar rvf $(IMGFILE_PATH) $(PACKAGES)/normal_boot_area.bin; \
							cd $(PACKAGES); \
						fi; \
					fi; \
					\
					cd ../../; \
				fi; \
			fi; \
			if [ '$(LAYOUT_USE_EMMC_SWAP)' = 'emmc_swap_true' ] ; then \
				dd if=tmp/swap_p.bin of=$(PACKAGES)/swap_p.bin bs=4096 count=1; \
				tar rvf $(IMGFILE_PATH) $(PACKAGES)/swap_p.bin; \
			fi; \
		fi; \
	fi

	$(QUIET) if [ '$(gen_install_binary)' = '0' ]; then \
		echo "gen install binary file"; \
		echo "start."; \
		if [ '$(LAYOUT)' = 'emmc' ] ; then \
			cd ./gen_binary/;./gen_binary_tool ../../install.img 2 $(gen_install_binary); \
		else \
			echo " nand or nor flash is not ready. exit."; \
		fi; \
	elif [ '$(gen_install_binary)' = '1' ]; then \
		echo "gen install binary file"; \
		echo "start."; \
		if [ '$(LAYOUT)' = 'emmc' ] ; then \
			cd ./gen_binary/;./gen_binary_tool ../../install.img 2 $(gen_install_binary); \
		else \
			echo " nand or nor flash is not ready. exit."; \
		fi; \
	fi;
endif

################## generate config.txt
.PHONY: gen_config
gen_config:
	$(QUIET) echo Setting: LAYOUT=$(LAYOUT) PROJECT_NAME=$(PROJECT_NAME) CUSTOMER_ID=$(CUSTOMER_ID)
	$(QUIET) echo
ifeq ($(ANDROID_IMGS), y)
ifneq ($(LIVEUPDATE_URL), )
	$(error No change LIVEUPDATE_URL for prebuilt images.)
endif
ifeq ($(AV_IN_ROOT), y)
	$(error We have not supported prebuilt images with AV in root.)
endif
endif

#	(sudo umount tmp/rootfs || true)
	$(QUIET) rm -rf tmp/* && mkdir -p tmp/pkgfile/$(TARGET)
	$(QUIET) if [ -d $(CUSTOMER_FOLDER)/info ]; then cp $(CUSTOMER_FOLDER)/info/* $(CUSTOMER_FOLDER)/../../factory/; fi
#for only-install_factory package
ifeq ($(only_install_factory), 1)
	$(QUIET) echo "only_factory=y" >> tmp/pkgfile/config.txt
	$(QUIET) echo "ifcmd0 = \"$(IFCMD0)\"" >> tmp/pkgfile/config.txt
	$(QUIET) echo "ifcmd1 = \"$(IFCMD1)\"" >> tmp/pkgfile/config.txt
	$(QUIET) if [ '$(stop_reboot)' = '1' ]; then echo "stop_reboot=y" >> tmp/pkgfile/config.txt; fi
	$(QUIET) if [ '$(logger_level)' != '0' ]; then \
		echo "logger_level="$(logger_level) >> tmp/pkgfile/config.txt; \
	fi
	$(QUIET) cd packages/$(TARGET)/factory$(FACTORY_SUFFIX) && tar cf ../factory.tar *
	$(QUIET) mv packages/$(TARGET)/factory.tar tmp/pkgfile/$(TARGET)/
	$(QUIET) cp installer/install_a tmp/pkgfile/
	$(QUIET) -grep -q 'start_customer=y' tmp/pkgfile/config.txt && \
	cp installer/customer.tar tmp/pkgfile/
	$(QUIET) cd tmp/pkgfile/ && tar cvf $(IMGFILE_PATH) *
else ifeq ($(only_install_bootcode), 1)
	$(QUIET) echo "only_bootcode=y" >> tmp/pkgfile/config.txt
	$(QUIET) echo "bootcode=y" >> tmp/pkgfile/config.txt
	$(QUIET) if [ '$(verify)' = '1' ]; then echo "verify=y" >> tmp/pkgfile/config.txt; fi
	$(QUIET) if [ '$(stop_reboot)' = '1' ]; then echo "stop_reboot=y" >> tmp/pkgfile/config.txt; fi
	$(QUIET) if [ '$(logger_level)' != '0' ]; then \
		echo "logger_level="$(logger_level) >> tmp/pkgfile/config.txt; \
	fi
	$(QUIET) cp packages/$(TARGET)/bootloader.tar tmp/pkgfile/$(TARGET)
	$(QUIET) cp packages/$(TARGET)/bootloader_lk.tar tmp/pkgfile/$(TARGET)
	$(QUIET) cp installer/install_a tmp/pkgfile/
	$(QUIET) -grep -q 'start_customer=y' tmp/pkgfile/config.txt && \
	cp installer/customer.tar tmp/pkgfile/
	$(QUIET) if [ "`ls -A packages/$(TARGET)/installer`" != ".svn" ] && [ "`ls -A packages/$(TARGET)/installer`" != "" ]; then \
		cp -R packages/$(TARGET)/installer/* tmp/pkgfile/; \
	fi
	$(QUIET) if [ '$(LAYOUT)' = 'nand' ]; then \
		cp $(CURDIR)/bin/rootfs/nandwrite tmp/pkgfile/; \
		cp $(CURDIR)/bin/rootfs/flash_erase tmp/pkgfile/; \
	fi
	$(QUIET) cd tmp/pkgfile/ && tar cvf $(IMGFILE_PATH) *
	$(QUIET) if [ '$(NAS_IMGS)' = 'y' ]; then \
		echo Original image size is `ls -lG $(IMGFILE_PATH) | awk -F' ' '{print $$4}'` && \
		if [ '$(hash_imgfile)' = 1 ]; then \
			if [ '$(SECURE_BOOT)' = y ]; then \
				dd if=/dev/zero  bs=1 count=`expr \( 4096000000 - \`ls -lG $(IMGFILE_PATH) | awk -F' ' '{print $$4}'\` - 256 \) % 4096` >> $(IMGFILE_PATH); \
				$(RTSSL_PATH) dgst -mars_sha1 -a -i $(IMGFILE_PATH) -sign -rsa -k $(RSA_PRIVATE_KEY); \
			else \
				dd if=/dev/zero  bs=1 count=`expr \( 4096000000 - \`ls -lG $(IMGFILE_PATH) | awk -F' ' '{print $$4}'\` - 20 \) % 4096` >> $(IMGFILE_PATH); \
				$(RTSSL_PATH) dgst -mars_sha1 -a -i $(IMGFILE_PATH) -sign -aes_128_ecb -k 0; \
			fi; \
		else \
			dd if=/dev/zero  bs=1 count=`expr \( 4096000000 - \`ls -lG $(IMGFILE_PATH) | awk -F' ' '{print $$4}'\` \) % 4096` >> $(IMGFILE_PATH); \
		fi; \
	fi
else
	########### new parameter  framework in config.txt
	$(QUIET) echo "# Package Information" >> tmp/pkgfile/config.txt;
	$(QUIET) echo "company=\"$(COMPANY)\"" >> tmp/pkgfile/config.txt;
	$(QUIET) echo "description=\"$(DESCRIPTION)\"" >> tmp/pkgfile/config.txt;
	$(QUIET) echo "modelname=\"$(MODELNAME)\"" >> tmp/pkgfile/config.txt;
	$(QUIET) echo "version=\"$(VERSION)\"" >> tmp/pkgfile/config.txt;
	$(QUIET) echo "releaseDate=\"$(RELEASEDATE)\"" >> tmp/pkgfile/config.txt;
	$(QUIET) echo "signature=\"$(SIGNATURE)\"" >> tmp/pkgfile/config.txt;
	$(QUIET) echo "# Package Configuration" >> tmp/pkgfile/config.txt;
	$(QUIET) -[ '$(NAS_IMGS)' = 'y' ] && [ '$(LAYOUT)' = 'spi' ] || \
	echo "start_customer=y" >> tmp/pkgfile/config.txt;
	$(QUIET) if [ '$(verify)' = '1' ]; then echo "verify=y" >> tmp/pkgfile/config.txt; fi
	$(QUIET) if [ '$(DUAL_BOOT)' = 'y' ]; then echo "nas_dual=y" >> tmp/pkgfile/config.txt; fi
	$(QUIET) if [ '$(install_bootloader)' = '1' ]; then echo "bootcode=y" >> tmp/pkgfile/config.txt; fi
	$(QUIET) if [ '$(install_factory)' = '1' ]; then echo "install_factory=y" >> tmp/pkgfile/config.txt; fi
	$(QUIET) if [ '$(install_dtb)' = '1' ]; then echo "install_dtb=y" >> tmp/pkgfile/config.txt; else echo "install_dtb=n" >> tmp/pkgfile/config.txt; fi
	$(QUIET) if [ '$(update_etc)' = '1' ]; then echo "update_etc=y" >> tmp/pkgfile/config.txt; fi
	$(QUIET) if [ '$(jffs2_nocleanmarker)' = '1' ]; then echo "jffs2_nocleanmarker=y" >> tmp/pkgfile/config.txt; fi
	$(QUIET) if [ '$(stop_reboot)' = '1' ]; then echo "stop_reboot=y" >> tmp/pkgfile/config.txt; fi 
	$(QUIET) echo "install_avfile_count=$(install_avfile_count)" >> tmp/pkgfile/config.txt;
	$(QUIET) if [ $(install_avfile_count) > 1 ] && [ -f ./packages/$(TARGET)/bluecore.video.zip ]; then echo "install_avfile_video_size=$(install_avfile_video_size)" >> tmp/pkgfile/config.txt; fi
	$(QUIET) if [ '$(LAYOUT)' = 'nand' ]; then echo "rba_percentage=$(rba_percentage)" >> tmp/pkgfile/config.txt; fi
	$(QUIET) if [ '$(stop_reboot)' = '0' ]; then echo "reboot_delay=$(reboot_delay)" >> tmp/pkgfile/config.txt; fi
	$(QUIET) if [ '$(logger_level)' != '0' ]; then echo "logger_level="$(logger_level) >> tmp/pkgfile/config.txt; fi
	$(QUIET) if [ '$(install_factory)' = '1' ]; then echo "ifcmd0 = \"$(IFCMD0)\"" >> tmp/pkgfile/config.txt; fi
	$(QUIET) if [ '$(install_factory)' = '1' ]; then echo "ifcmd1 = \"$(IFCMD1)\"" >> tmp/pkgfile/config.txt; fi	
	$(QUIET) if [ '$(efuse_key)' = '1' ]; then echo "efuse_key=1" >> tmp/pkgfile/config.txt; else echo "efuse_key=0" >> tmp/pkgfile/config.txt; fi
	$(QUIET) if [ '$(rpmb_fw)' = '1' ]; then echo "rpmb_fw=1" >> tmp/pkgfile/config.txt; else echo "rpmb_fw=0" >> tmp/pkgfile/config.txt; fi
	$(QUIET) if [ '$(ANDROID_BRANCH)' = 'android-9' ]; then echo "boot_image=1" >> tmp/pkgfile/config.txt; fi
	$(QUIET) if [ '$(SECURE_BOOT)' = y ] && [ '$(VMX)' = n ]; then \
		echo "secure_boot=1" >> tmp/pkgfile/config.txt; \
		if [ '$(ANDROID_BRANCH)' = 'android-9' ]; then \
			echo "fw = boot $(TARGET)/bootimg.bin.aes $(BOOTIMAGEDDR)" >> tmp/pkgfile/config.txt; \
			echo "fw = boot2 $(TARGET)/bootimg.bin.aes $(BOOTIMAGEDDR)" >> tmp/pkgfile/config.txt; \
			echo "fw = recovery $(TARGET)/recoveryimg.bin.aes $(RESCUEIMAGEDDR)" >> tmp/pkgfile/config.txt; \
			echo "fw = recovery2 $(TARGET)/recoveryimg.bin.aes $(RESCUEIMAGEDDR)" >> tmp/pkgfile/config.txt; \
			echo "fw = audio2 $(TARGET)/$(AUDIO_FILE) $(AUDIOADDR)" >> tmp/pkgfile/config.txt; \
		else \
			if [ '$(DTB_ENC)' = 'y' ]; then \
				echo "fw = rescueDT2 $(TARGET)/rescue.$(LAYOUT).dtb.aes $(KERNELDT_ADDR)" >> tmp/pkgfile/config.txt; \
			else \
				echo "fw = rescueDT2 $(TARGET)/rescue.$(LAYOUT).dtb $(KERNELDT_ADDR)" >> tmp/pkgfile/config.txt; \
			fi; \
			echo "fw = RootFS2 $(TARGET)/rescue.root.$(LAYOUT).cpio.gz_pad.img$(F_EXT).aes  $(KERNELROOTFSADDR)" >> tmp/pkgfile/config.txt; \
			echo "fw = Kernel2 $(TARGET)/$(LAYOUT).uImage$(F_EXT).aes $(LINUXADDR)" >> tmp/pkgfile/config.txt; \
			echo "fw = kernelDT2 $(TARGET)/android.$(LAYOUT).dtb.aes $(KERNELDT_ADDR)" >> tmp/pkgfile/config.txt; \
			if [ '$(NAS_IMGS)' != 'y' ] && [ '$(ANDROID_IMGS)' = 'y' ]; then \
				echo "fw = kernelRootFS2 $(TARGET)/android.root.$(LAYOUT).cpio.gz_pad.img$(F_EXT).aes $(KERNELROOTFSADDR)" >> tmp/pkgfile/config.txt; \
			fi; \
			if [ '$(TEE_FW)' = 'y' ]; then \
				echo "fw = tee $(TARGET)/tee_enc.bin.aes $(TEEADDR)" >> tmp/pkgfile/config.txt; \
				echo "fw = BL31 $(TARGET)/bl31_enc.bin.aes $(BL31ADDR)" >> tmp/pkgfile/config.txt; \
			fi; \
			if [ '$(DTB_ENC)' = 'y' ]; then \
				echo "fw = rescueDT $(TARGET)/rescue.$(LAYOUT).dtb.aes $(RESCUEDT_ADDR)" >> tmp/pkgfile/config.txt; \
				echo "fw = kernelDT $(TARGET)/android.$(LAYOUT).dtb.aes $(KERNELDT_ADDR)" >> tmp/pkgfile/config.txt; \
			else \
				echo "fw = rescueDT $(TARGET)/rescue.$(LAYOUT).dtb $(RESCUEDT_ADDR)" >> tmp/pkgfile/config.txt; \
				echo "fw = kernelDT $(TARGET)/android.$(LAYOUT).dtb $(KERNELDT_ADDR)" >> tmp/pkgfile/config.txt; \
			fi; \
			echo "fw = rescueRootFS $(TARGET)/rescue.root.$(LAYOUT).cpio.gz_pad.img$(F_EXT).aes $(RESCUEROOTFSADDR)" >> tmp/pkgfile/config.txt; \
			if [ '$(NAS_IMGS)' != 'y' ] && [ '$(ANDROID_IMGS)' = 'y' ]; then \
				echo "fw = kernelRootFS $(TARGET)/android.root.$(LAYOUT).cpio.gz_pad.img$(F_EXT).aes $(KERNELROOTFSADDR)" >> tmp/pkgfile/config.txt; \
			fi; \
			echo "fw = linuxKernel $(TARGET)/$(LAYOUT).uImage$(F_EXT).aes $(LINUXADDR)" >> tmp/pkgfile/config.txt; \
		fi; \
		echo "fw = audioKernel $(TARGET)/$(AUDIO_FILE) $(AUDIOADDR)" >> tmp/pkgfile/config.txt; \
		echo "fw = audio2 $(TARGET)/$(AUDIO_FILE) $(AUDIOADDR)" >> tmp/pkgfile/config.txt; \
		if [ '$(HYPERVISOR)' = 'y' ] && [ '$(NAS_IMGS)' = 'y' ]; then \
		echo "fw = XenOS $(TARGET)/xen.img.aes $(XENADDR)" >> tmp/pkgfile/config.txt; \
		fi; \
		echo "fw = pcpu $(TARGET)/pcpu.$(LAYOUT).bin 0x20000000" >> tmp/pkgfile/config.txt; \
		echo "fw = pcpu2 $(TARGET)/pcpu.$(LAYOUT).bin 0x20000000" >> tmp/pkgfile/config.txt; \
	elif [ '$(VMX)' = y ]; then \
		if [ '$(SECURE_BOOT)' = y ]; then \
			echo "secure_boot=1" >> tmp/pkgfile/config.txt; \
		else \
			echo "secure_boot=0" >> tmp/pkgfile/config.txt; \
		fi; \
		echo "vmx=y" >> tmp/pkgfile/config.txt; \
		if [ '$(vmx_test_mode)' = '1' ]; then \
			echo "testMode=1" >> tmp/pkgfile/config.txt; \
		else \
			echo "testMode=0" >> tmp/pkgfile/config.txt; \
		fi; \
	else \
		echo "secure_boot=0" >> tmp/pkgfile/config.txt; \
		if [ '$(ANDROID_BRANCH)' = 'android-9' ]; then \
			echo "fw = boot $(TARGET)/bootimg.bin $(BOOTIMAGEDDR)" >> tmp/pkgfile/config.txt; \
			echo "fw = boot2 $(TARGET)/bootimg.bin $(BOOTIMAGEDDR)" >> tmp/pkgfile/config.txt; \
			echo "fw = recovery $(TARGET)/recoveryimg.bin $(RESCUEIMAGEDDR)" >> tmp/pkgfile/config.txt; \
			echo "fw = recovery2 $(TARGET)/recoveryimg.bin $(RESCUEIMAGEDDR)" >> tmp/pkgfile/config.txt; \
			echo "fw = audio2 $(TARGET)/$(AUDIO_FILE) $(AUDIOADDR)" >> tmp/pkgfile/config.txt; \
			echo "fw = pcpu2 $(TARGET)/pcpu.$(LAYOUT).bin 0x20000000" >> tmp/pkgfile/config.txt; \
		else \
			if [ '$(NAS_IMGS)' = 'y' ] && [ '$(LAYOUT)' = 'spi' ] || [ '$(DUAL_BOOT)' = 'y' ]; then \
				echo "[NAS]Skip golden fw entries" ; \
			else \
				echo "fw = rescueDT2 $(TARGET)/rescue.$(LAYOUT).dtb $(RESCUEDT_ADDR)" >> tmp/pkgfile/config.txt; \
				echo "fw = RootFS2 $(TARGET)/rescue.root.$(LAYOUT).cpio.gz_pad.img$(F_EXT) $(RESCUEROOTFSADDR)" >> tmp/pkgfile/config.txt; \
				echo "fw = Kernel2 $(TARGET)/$(LAYOUT).uImage$(F_EXT) $(LINUXADDR)" >> tmp/pkgfile/config.txt; \
				echo "fw = audio2 $(TARGET)/$(AUDIO_FILE) $(AUDIOADDR)" >> tmp/pkgfile/config.txt; \
				echo "fw = kernelDT2 $(TARGET)/android.$(LAYOUT).dtb $(KERNELDT_ADDR) $(KERNELDT_MINSIZE)" >> tmp/pkgfile/config.txt; \
				if [ '$(NAS_IMGS)' != 'y' ] && [ '$(ANDROID_IMGS)' = 'y' ]; then \
					echo "fw = kernelRootFS2 $(TARGET)/android.root.$(LAYOUT).cpio.gz_pad.img$(F_EXT) $(KERNELROOTFSADDR)" >> tmp/pkgfile/config.txt; \
				fi; \
				echo "fw = pcpu2 $(TARGET)/pcpu.$(LAYOUT).bin 0x20000000" >> tmp/pkgfile/config.txt; \
			fi; \
			echo "fw = kernelDT $(TARGET)/android.$(LAYOUT).dtb $(KERNELDT_ADDR) $(KERNELDT_MINSIZE)" >> tmp/pkgfile/config.txt; \
			if [ '$(DUAL_BOOT)' != 'y' ]; then \
				echo "fw = rescueDT $(TARGET)/rescue.$(LAYOUT).dtb $(RESCUEDT_ADDR) $(RESCUEDT_MINSIZE)" >> tmp/pkgfile/config.txt; \
				echo "fw = rescueRootFS $(TARGET)/rescue.root.$(LAYOUT).cpio.gz_pad.img$(F_EXT) $(RESCUEROOTFSADDR) $(RESCUEROOTFS_MINSIZE)" >> tmp/pkgfile/config.txt; \
			fi; \
			if [ '$(NAS_IMGS)' != 'y' ] && [ '$(ANDROID_IMGS)' = 'y' ]; then \
				echo "fw = kernelRootFS $(TARGET)/android.root.$(LAYOUT).cpio.gz_pad.img$(F_EXT) $(KERNELROOTFSADDR)" >> tmp/pkgfile/config.txt; \
			fi; \
			if [ -f ./packages/$(TARGET)/$(LAYOUT).uImage ]; then echo "fw = linuxKernel $(TARGET)/$(LAYOUT).uImage $(LINUXADDR) $(LINUX_MINSIZE)" >> tmp/pkgfile/config.txt; fi; \
		fi; \
		echo "fw = audioKernel $(TARGET)/$(AUDIO_FILE) $(AUDIOADDR) $(AUDIO_MINSIZE)" >> tmp/pkgfile/config.txt; \
		if [ '$(TEE_FW)' = 'y' ]; then \
			echo "fw = tee $(TARGET)/tee_enc.bin $(TEEADDR)" >> tmp/pkgfile/config.txt; \
			echo "fw = BL31 $(TARGET)/bl31_enc.bin $(BL31ADDR)" >> tmp/pkgfile/config.txt; \
			if [ '$(enable_ab_system)' = 'y' ]; then \
				echo "fw = lk $(TARGET)/lk_ab.bin $(LK_ADDR)" >> tmp/pkgfile/config.txt; \
			fi; \
		fi; \
		if [ '$(HYPERVISOR)' = 'y' ] && [ '$(NAS_IMGS)' = 'y' ]; then \
			echo "fw = XenOS $(TARGET)/xen.img $(XENADDR)" >> tmp/pkgfile/config.txt; \
		fi; \
		echo "fw = pcpu $(TARGET)/pcpu.$(LAYOUT).bin 0x20000000" >> tmp/pkgfile/config.txt; \
	fi
	$(QUIET) if [ '$(VMX)' = n ]; then \
		if [ -f ./packages/$(TARGET)/uboot.bin ]; then \
			echo "fw = UBOOT $(TARGET)/uboot.bin 0x00020000" >> tmp/pkgfile/config.txt; \
		fi; \
		if [ -f ./packages/$(TARGET)/bootfile.audio ] && [ $(install_avfile_count) -gt 0 ]; then \
           		echo "fw = audioFile $(TARGET)/bootfile.audio 0xdeaddead" >> tmp/pkgfile/config.txt; \
        	fi; \
		if [ -f ./packages/$(TARGET)/bootfile.video ] && [ $(install_avfile_count) -gt 0 ]; then \
           		echo "fw = videoFile $(TARGET)/bootfile.video 0xdeaddead" >> tmp/pkgfile/config.txt; \
        	fi; \
		if [ -f ./packages/$(TARGET)/bootfile.image ] && [ $(install_avfile_count) -gt 0 ]; then \
			if [ '$(NAS_IMGS)' = 'y' ] && [ '$(LAYOUT)' = 'nand' ]; then \
				echo "fw = imageFile $(TARGET)/bootfile.lzma $(BOOTFILE_IMAGE_ADDR) $(LOGO_MINSIZE)" >> tmp/pkgfile/config.txt; \
			else \
			echo "fw = imageFile $(TARGET)/bootfile.image $(BOOTFILE_IMAGE_ADDR) $(LOGO_MINSIZE)" >> tmp/pkgfile/config.txt; \
			fi; \
        	fi; \
	fi
	$(QUIET) if [ '$(LAYOUT)' = 'emmc' ] || [ '$(LAYOUT)' = 'nand' ] || [ '$(LAYOUT)' = 'spi' ] || [ '$(LAYOUT)' = 'sata' ]; then \
        if [ '$(LAYOUT_USE_EMMC_SWAP)' = 'emmc_swap_true' ] ; then \
			cat $(CUSTOMER_FOLDER)/partition.emmc_swap_700MB.txt | sed s/target_pkg/$(TARGET)/ >> tmp/pkgfile/config.txt; \
        else \
			if [ '$(ANDROID_BRANCH)' = 'android-8' ] && [ '$(enable_ab_system)' = 'y' ]; then \
				cat $(CUSTOMER_FOLDER)/partition_GPT_AB.txt | sed s/target_pkg/$(TARGET)/ >> tmp/pkgfile/config.txt; \
			elif [ '$(ANDROID_BRANCH)' = 'android-8' ] || [ '$(ANDROID_BRANCH)' = 'android-9' ]; then \
				cat $(CUSTOMER_FOLDER)/partition_GPT.txt | sed s/target_pkg/$(TARGET)/ >> tmp/pkgfile/config.txt; \
			else \
				cat $(CUSTOMER_FOLDER)/partition.txt | sed s/target_pkg/$(TARGET)/ >> tmp/pkgfile/config.txt; \
			fi; \
		fi; \
	fi
	$(QUIET) if [ '$(LAYOUT)' = 'emmc' ] || [ '$(LAYOUT)' = 'nand' ] || [ '$(LAYOUT)' = 'sata' ]; then \
		if [ '$(HYPERVISOR)' = 'y' ] && [ '$(NAS_IMGS)' = 'y' ]; then \
			if [ '$(LAYOUT)' = 'emmc' ]; then \
				echo "part = xen /domu ext4 $(TARGET)/xen.bin 67108864" >> tmp/pkgfile/config.txt; \
			fi; \
			if [ '$(LAYOUT)' = 'sata' ]; then \
				echo "part = xen /domu ext4 $(TARGET)/xen.bin 67108864" >> tmp/pkgfile/config.txt; \
			fi; \
		fi; \
		if [ -f $(CUSTOMER_FOLDER)/partition_customize.txt ]; then \
			cat $(CUSTOMER_FOLDER)/partition_customize.txt >> tmp/pkgfile/config.txt; \
		fi; \
	fi
endif

################ copy files to specific directory for after processing them
.PHONY: prepare_file
prepare_file:
	#don't need ta encryption

	#### VMX copy the system and vendor partition to root
	$(QUIET) if [ '$(ANDROID_IMGS)' = y ]; then \
		if [ '$(VMX)' == y ]; then \
			if [ '$(VMX_TYPE)' = 'ultra' ]; then \
				if [ "`readlink $(CURDIR)/packages/$(PACKAGES)/root`" != "" ]; then \
					rm -rf $(CURDIR)/packages/$(PACKAGES)/root/system; \
					rm -rf $(CURDIR)/packages/$(PACKAGES)/root/vendor; \
					cp -r --remove-destination `readlink $(CURDIR)/packages/$(PACKAGES)/system` $(CURDIR)/packages/$(PACKAGES)/root/; \
					cp -r --remove-destination `readlink $(CURDIR)/packages/$(PACKAGES)/vendor` $(CURDIR)/packages/$(PACKAGES)/root/; \
					rm -rf $(CURDIR)/packages/$(PACKAGES)/root/vendor/modules/8*; \
				fi; \
			else \
				if [ "`readlink $(CURDIR)/packages/$(PACKAGES)/root`" != "" ]; then \
					cp -r --remove-destination `readlink $(CURDIR)/packages/$(PACKAGES)/system` $(CURDIR)/packages/$(PACKAGES)/root/; \
					cp -r --remove-destination `readlink $(CURDIR)/packages/$(PACKAGES)/vendor` $(CURDIR)/packages/$(PACKAGES)/root/; \
				fi; \
			fi; \
		fi; \
	fi;

	#### copy install_a / teeUtility.tar / config.txt / customer.tar / ALSADaemon / utility
	if [ '$(ANDROID_BRANCH)' = 'android-8' ] && [ '$(enable_ab_system)' = 'y' ]; then \
		cp -R installer/install_a_GPT_AB tmp/pkgfile/install_a; \
	elif [ '$(ANDROID_BRANCH)' = 'android-8' ] || [ '$(ANDROID_BRANCH)' = 'android-9' ]; then \
		cp -R installer/install_a_thor_GPT tmp/pkgfile/install_a; \
	elif [ '$(VMX)' = 'y' ] && [ '$(VMX_TYPE)' = 'ultra' ]; then \
		cp -R installer/install_a_1395.vmx.ultra tmp/pkgfile/install_a; \
	else \
		cp -R installer/install_a_thor tmp/pkgfile/install_a; \
	fi;
	$(QUIET) if [ '$(NAS_IMGS)' = 'y' ] && [ '$(ANDROID_IMGS)' != 'y' ]; then \
		cp -R installer/teeUtility_nas.tar tmp/pkgfile/teeUtility.tar; \
	else \
		cp -R installer/teeUtility_thor.tar tmp/pkgfile/teeUtility.tar; \
	fi;
	$(QUIET) -grep -q 'start_customer=y' tmp/pkgfile/config.txt && \
	cp -R installer/customer.tar tmp/pkgfile/
	$(QUIET) -grep -q 'start_customer=y' tmp/pkgfile/config.txt && \
	cp -R installer/ALSADaemon tmp/pkgfile/

	$(QUIET) if [ '$(LAYOUT)' = 'nand' ]; then \
		cp $(CURDIR)/bin/rootfs/ubiformat tmp/pkgfile/; \
		cp $(CURDIR)/bin/rootfs/nandwrite tmp/pkgfile/; \
		cp $(CURDIR)/bin/rootfs/flash_erase tmp/pkgfile/; \
		if [ '$(NAS_IMGS)' != 'y' ]; then \
		cp $(CURDIR)/bin/rootfs/nandwrite packages/$(TARGET)/rootfs/usr/bin; \
		cp $(CURDIR)/bin/rootfs/flash_erase packages/$(TARGET)/rootfs/usr/bin; \
		fi; \
	elif [ '$(LAYOUT)' = 'emmc' ]; then \
		cp $(CURDIR)/bin/rootfs/mke2fs tmp/pkgfile/; \
		if [ '$(LAYOUT_USE_EMMC_SWAP)' = 'emmc_swap_true' ] ; then \
			cp $(CURDIR)/bin/rootfs/mkswap tmp/pkgfile/; \
		fi; \
	elif [ '$(LAYOUT)' = 'sata' ]; then \
		cp $(CURDIR)/bin/rootfs/mke2fs tmp/pkgfile/; \
	elif [ '$(LAYOUT)' = 'spi' ]; then \
		cp $(CURDIR)/bin/rootfs/flash_erase tmp/pkgfile/; \
		cp $(CURDIR)/bin/rootfs/resize2fs tmp/pkgfile/; \
	fi
	$(QUIET) if [ "`ls -A packages/$(TARGET)/installer`" != ".svn" ] && [ "`ls -A packages/$(TARGET)/installer`" != "" ]; then \
		if [ '$(VMX)' = 'y' ] && [ '$(VMX_TYPE)' != 'ultra' ] && [ -f packages/$(TARGET)/installer/install_a_1395.vmx.ultra ]; then \
			cp -R packages/$(TARGET)/installer/install_a_1395.vmx.ultra tmp/pkgfile/install_a; \
		elif [ -f packages/$(TARGET)/installer/install_a_thor ]; then \
			cp -R packages/$(TARGET)/installer/install_a_thor tmp/pkgfile/install_a; \
		else \
			cp -R packages/$(TARGET)/installer/* tmp/pkgfile/; \
		fi; \
	fi

	$(QUIET) rm -f $(IMGFILE_AP_PATH);

	# untar rootfs
	$(QUIET) mkdir -p tmp/rootfs 

	# copy android rootfs / rescue rootfs / rescue DT / linux DT to package
	$(QUIET) if [ -f ./packages/$(TARGET)/bootfile.audio ] && [ $(install_avfile_count) -gt 0 ]; then \
		cp packages/$(TARGET)/bootfile.audio tmp/pkgfile/$(TARGET)/; \
	fi;
	$(QUIET) if [ -f ./packages/$(TARGET)/bootfile.video ] && [ $(install_avfile_count) -gt 0 ]; then \
		cp packages/$(TARGET)/bootfile.video tmp/pkgfile/$(TARGET)/; \
	fi;
	$(QUIET) if [ '$(VMX)' = y ]; then \
		if [ -f ./packages/$(TARGET)/bootfile_vmx.image ] && [ $(install_avfile_count) -gt 0 ]; then \
			cp packages/$(TARGET)/bootfile_vmx.image tmp/pkgfile/$(TARGET)/; \
		fi; \
	else \
		if [ -f ./packages/$(TARGET)/bootfile.image ] && [ $(install_avfile_count) -gt 0 ]; then \
			if [ '$(NAS_IMGS)' = 'y' ] && [ '$(LAYOUT)' = 'nand' ]; then \
				$(LZMA_PATH) e packages/$(TARGET)/bootfile.image tmp/pkgfile/$(TARGET)/bootfile.lzma; \
			else \
			cp packages/$(TARGET)/bootfile.image tmp/pkgfile/$(TARGET)/; \
			fi; \
		fi; \
	fi;

	# unzip AV firmwares
	$(QUIET) cd tmp/ && cp ../packages/$(TARGET)/System.map.audio ./ && unzip -o ../packages/$(TARGET)/bluecore.audio.zip > /dev/null && cd ../; \

	### gen android rootfs
	# Precedence of Android rootfs on NAS:
	#   package5/root, android.$(LAYOUT).tar.bz2, /mnt/android in NAS rootfs
	$(QUIET) if [ '$(NAS_IMGS)' = 'y' ]; then \
		echo "extracting rootfs from root.$(LAYOUT).tar.bz2" && \
		cd tmp && \
		if [ '$(LAYOUT)' = 'nand' ] || [ '$(LAYOUT)' = 'emmc' ] || [ '$(LAYOUT)' = 'sata' ]; then \
			echo "Creating NAS $(LAYOUT) images ....." && \
			$(RUNCMD_PATH) $(layout_type) $(layout_size) $(TARGET) $(CUSTOMER_ID) $(LAYOUT_USE_EMMC_SWAP); \
			echo "Runnning runCmd.pl ....."; \
		elif [ '$(LAYOUT)' = 'spi' ]; then \
			echo "Creating NAS SPI + HDD images ....." && \
			fakeroot ../packages/$(TARGET)/mkrootfs.sh $(LAYOUT); \
		fi; \
		cd ../; \
	elif [ '$(ANDROID_IMGS)' = 'y' ]; then \
		echo "run rtssl to enc file" && \
		if [ -f $(RSA_LIB_PRIVATE_KEY) ]; then \
			openssl rsa -in $(RSA_LIB_PRIVATE_KEY) -pubout -out $(RSA_LIB_PUB_KEY); \
		fi; \
		for file in $(LIBFILE); do \
			if [ -f ./packages/$(TARGET)/$${file} ] && [ -f $(RSA_LIB_PRIVATE_KEY) ]; then \
				$(DO_SHA256_PATH) ./packages/$(TARGET)/$${file} ./packages/$(TARGET)/$${file}.padding ./packages/$(TARGET)/$${file}.sig; \
				$(RTSSL_PATH) enc -e -rsa -k $(RSA_LIB_PRIVATE_KEY) -i ./packages/$(TARGET)/$${file}.sig -o ./packages/$(TARGET)/$${file}.rsa; \
				$(LIB_ENC_PATH) ./packages/$(TARGET)/$${file} ./packages/$(TARGET)/$${file}.enc;  \
				if [ '$(SECURE_BOOT)' = y ]; then \
					$(DO_SHA256_PATH) ./packages/$(TARGET)/$${file}.enc ./packages/$(TARGET)/$${file}.otp.padding ./packages/$(TARGET)/$${file}.otp.sig; \
					$(RTSSL_PATH) enc -e -rsa -k $(RSA_LIB_PRIVATE_KEY) -i ./packages/$(TARGET)/$${file}.otp.sig -o ./packages/$(TARGET)/$${file}.otp.rsa; \
					#$(LIB_ENC_PATH) ./packages/$(TARGET)/$${file} ./packages/$(TARGET)/$${file}.enc;  \
					$(RTSSL_PATH) enc -e -aes_128_ecb -k `hexdump -e '8/1 "%02x"' $(SECURE_KEY_FILE)` -i ./packages/$(TARGET)/$${file}.enc -o ./packages/$(TARGET)/$${file}.otp.enc; \
				else \
					cp ./packages/$(TARGET)/$${file}.enc ./packages/$(TARGET)/$${file}.otp.enc; \
				fi; \
				rm ./packages/$(TARGET)/$${file}.padding ./packages/$(TARGET)/$${file}.sig ./packages/$(TARGET)/$${file}.enc ./packages/$(TARGET)/$${file} -f;sync;sync; \
			fi; \
		done ; \
		if [ '$(VMX)' = 'y' ]; then \
			echo "run mkrootfs_vmx.sh to pack root image with padding" && \
			./packages/$(TARGET)/mkrootfs_vmx.sh $(LAYOUT); \
		else \
			echo "run mkrootfs.sh to pack root image with padding" && \
			./packages/$(TARGET)/mkrootfs.sh $(LAYOUT); \
		fi; \
	fi
	
	$(QUIET) if [ -f ./packages/$(TARGET)/android.root.$(LAYOUT).cpio.gz_pad.img ]; then \
		cp packages/$(TARGET)/android.root.$(LAYOUT).cpio.gz_pad.img tmp/; \
	fi;
	$(QUIET) if [ '$(VMX)' = 'n' ] && [ '$(ANDROID_IMGS)' = 'y' ]; then \
		if [ '$(ANDROID_BRANCH)' = 'android-9' ]; then \
			cd packages/$(TARGET)/recovery/ && \
			rm -rf rootfs_recovery/; \
			mkdir rootfs_recovery/; \
			cp -rf $(CURDIR)/../../android/out/target/product/$(ANDROID_PRODUCT)/recovery/root/* rootfs_recovery/; \
			rm rootfs_recovery/*; \
			cp $(CURDIR)/../../android/out/target/product/$(ANDROID_PRODUCT)/recovery/root/*default* rootfs_recovery/; \
			rm -rf rootfs_recovery/bin rootfs_recovery/sbin/ rootfs_recovery/system; \
			if [ '$(TARGET_CHIP_ARCH)' = 'arm32' ]; then \
				cp -rf 32bit/* rootfs_recovery/; \
			else \
				cp -rf 64bit/* rootfs_recovery/; \
			fi; \
			cp $(CURDIR)/../../android/out/target/product/$(ANDROID_PRODUCT)/recovery/root/sbin/recovery rootfs_recovery/sbin/recovery; \
			./mkrootfs.sh; \
			cp rescue.root.emmc.cpio.gz_pad.img $(TMP)/rescue.root.$(LAYOUT).cpio.gz_pad.img; \
		else \
			if [ '$(TARGET_CHIP_ARCH)' = 'arm64' ]; then \
				cp packages/$(TARGET)/rescue.root.$(LAYOUT).cpio.gz_pad_GPT.img tmp/rescue.root.$(LAYOUT).cpio.gz_pad.img; \
			else \
				cp packages/$(TARGET)/rescue.root.$(LAYOUT).cpio.gz_pad_32bit.img tmp/rescue.root.$(LAYOUT).cpio.gz_pad.img; \
			fi; \
		fi; \
	fi;
	$(QUIET) if [ -f ./packages/$(TARGET)/rescue.root.$(LAYOUT).cpio.gz_pad.img.vmx ] && [ '$(VMX)' = 'y' ]; then \
		if [ '$(VMX_TYPE)' = 'ultra' ]; then \
			cp packages/$(TARGET)/rescue.root.$(LAYOUT).cpio.gz_pad.img.vmx.ultra tmp/; \
		else \
			cp packages/$(TARGET)/rescue.root.$(LAYOUT).cpio.gz_pad.img.vmx tmp/; \
		fi; \
	fi;
	$(QUIET) if [ '$(LNX_IMGS)' = 'y' ]; then \
		if [ '$(LAYOUT)' = 'emmc' ]; then \
			if [ '$(TARGET_ARCH)' = 'arm' ]; then \
				cp packages/$(TARGET)/rescue.root.$(LAYOUT).cpio.gz_pad_32bit.img tmp/rescue.root.$(LAYOUT).cpio.gz_pad.img; \
			else \
				cp packages/$(TARGET)/rescue.root.$(LAYOUT).cpio.gz_pad.img tmp/rescue.root.$(LAYOUT).cpio.gz_pad.img; \
			fi; \
		else \
			cp packages/$(TARGET)/rescue.root.emmc.cpio.gz_pad.img tmp/rescue.root.$(LAYOUT).cpio.gz_pad.img; \
		fi; \
	fi;
	# Use nand rescue rootfs for Pure NAS on eMMC
	$(QUIET) if [ '$(NAS_IMGS)' = 'y' ] && [ '$(ANDROID_IMGS)' != 'y' ] && [ '$(LAYOUT)' = 'emmc' ]; then \
		cp packages/$(TARGET)/rescue.root.nand.cpio.gz_pad.img tmp/rescue.root.$(LAYOUT).cpio.gz_pad.img; \
	fi;

	# device tree [DT]
	$(QUIET) if [ -f ./packages/$(TARGET)/android.$(LAYOUT).dtb ]; then \
		if [ '$(SECURE_BOOT)' = y ] && [ '$(DTB_ENC)' = 'y' ] || [ '$(ANDROID_BRANCH)' = 'android-9' ]; then \
			cp packages/$(TARGET)/android.$(LAYOUT).dtb tmp/; \
		else \
			cp packages/$(TARGET)/android.$(LAYOUT).dtb tmp/pkgfile/$(TARGET)/; \
		fi; \
	fi;
	$(QUIET) if [ -f ./packages/$(TARGET)/rescue.$(LAYOUT).dtb ]; then \
		if [ '$(SECURE_BOOT)' = y ] && [ '$(DTB_ENC)' = 'y' ] || [ '$(ANDROID_BRANCH)' = 'android-9' ]; then \
			cp packages/$(TARGET)/rescue.$(LAYOUT).dtb tmp/; \
		else \
			if [ '$(DUAL_BOOT)' != 'y' ]; then \
			cp packages/$(TARGET)/rescue.$(LAYOUT).dtb tmp/pkgfile/$(TARGET)/; \
			fi; \
		fi; \
	fi;

	# uImage, linux kernel
	$(QUIET) if [ -f ./packages/$(TARGET)/$(LAYOUT).uImage ]; then \
		cp packages/$(TARGET)/$(LAYOUT).uImage tmp/; \
	fi;
	$(QUIET) if [ -f ./packages/$(TARGET)/gold.$(LAYOUT).uImage ] && [ '$(SHRINK_GOLDEN_IMG)' = 'true' ]; then \
		cp packages/$(TARGET)/gold.$(LAYOUT).uImage tmp/$(LAYOUT).uImage2; \
	fi;

	# uboot.bin, uboot 64.
	$(QUIET) if [ -f ./packages/$(TARGET)/uboot.bin ]; then \
		cp packages/$(TARGET)/uboot.bin tmp/; \
	fi;

	#ver.txt: fw version info
	$(QUIET) if [ -f ./packages/$(TARGET)/ver.txt ] && [ '$(ANTI_ROLLBACK)' = 'y' ]; then \
		cp packages/$(TARGET)/ver.txt tmp/; \
	fi;

	#sysVer.txt: install.img version info
	$(QUIET) if [ -f ./packages/$(TARGET)/sysVer.txt ] && [ '$(ANTI_ROLLBACK)' = 'y' ]; then \
		cp packages/$(TARGET)/sysVer.txt tmp/; \
	fi;

	#goldVer.txt: golden fw version info
	$(QUIET) if [ -f ./packages/$(TARGET)/goldVer.txt ] && [ '$(ANTI_ROLLBACK)' = 'y' ]; then \
		cp packages/$(TARGET)/goldVer.txt tmp/; \
	elif [ -f ./packages/$(TARGET)/ver.txt ] && [ '$(ANTI_ROLLBACK)' = 'y' ]; then \
		cp packages/$(TARGET)/ver.txt tmp/goldVer.txt; \
	fi;

	$(QUIET) if [ '$(TEE_FW)' = 'y' ] && [ '$(VMX)' = 'n' ]; then \
		cp ./packages/$(TARGET)/tee_enc.bin ./tmp; \
		cp ./packages/$(TARGET)/bl31_enc.bin ./tmp; \
		if [ '$(enable_ab_system)' = 'y' ]; then \
			cp ./packages/$(TARGET)/lk_ab.bin ./tmp; \
		fi; \
	fi

	$(QUIET) if [ '$(HYPERVISOR)' = 'y' ] && [ '$(NAS_IMGS)' = 'y' ]; then \
		if [ -f ./packages/$(TARGET)/xen.img ]; then cp packages/$(TARGET)/xen.img tmp/pkgfile/$(TARGET)/; fi; \
	fi;

	#install factory
	$(QUIET) if [ '$(install_factory)' = 1 ]; then \
		cd packages/$(TARGET)/factory$(FACTORY_SUFFIX) && tar cvf ../factory.tar *; \
		cd ../../../ && mv packages/$(TARGET)/factory.tar tmp/pkgfile/$(TARGET)/; \
	fi

	# install AP
	$(QUIET) if [ '$(install_ap)' = 1 ]; then \
		cd packages/$(TARGET)/ap/bin && \
		date +"%Y%m%d_%H:%M" > release.date; \
	fi
	
	# re-compress kernel images, 
	### and pack user partition rootfs, usr/local/etc image
	$(QUIET) if [ '$(NAS_IMGS)' != 'y' ]; then \
	if [ '$(LAYOUT)' = 'spi' ]; then \
		echo "Now we don't support nor flash ....."; \
	elif [ '$(LAYOUT)' = 'nand' ]; then \
		cd tmp && \
		if [ '$(ANDROID_IMGS)' = 'y' ] || [ '$(LNX_IMGS)' = 'y' ]; then \
			cd $(TMP) && \
			echo "Creating ubifs image ....." && \
			echo "Runnning runCmd.pl ....." && \
			$(RUNCMD_PATH) $(layout_type) $(layout_size) $(TARGET) || exit 1; \
		fi; \
	elif [ '$(LAYOUT)' = 'emmc' ] || [ '$(LAYOUT)' = 'sata' ]; then \
        if [ '$(ANDROID_IMGS)' = 'y' ]; then \
			cd $(TMP) && \
			echo "Creating ext4 image (max system partition pretend is SYSTEM_MINSIZE) ....." ; \
			cd $(TMP) && \
			echo "Runnning runCmd.pl ....." && \
			$(RUNCMD_PATH) $(layout_type) $(layout_size) $(TARGET) $(CUSTOMER_ID) $(LAYOUT_USE_EMMC_SWAP) $(ANDROID_BRANCH) $(enable_ab_system) $(enable_dm_verity) || exit 1; \
		elif [ '$(LNX_IMGS)' = 'y' ]; then \
			echo "copy ext4 rootfs image ....."; \
			cp $(CURDIR)/packages/$(TARGET)/$(EXT4FS_ROOTFSIMG) $(TMP)/.;sync; \
			cd $(TMP) && \
			echo "Creating ext4 image (max system partition pretend is SYSTEM_MINSIZE) ....." ; \
			cd $(TMP) && \
			echo "Runnning runCmd.pl ....." && \
			$(RUNCMD_PATH) $(layout_type) $(layout_size) $(TARGET) || exit 1; \
        fi ; \
        fi ; \
	fi
			
	###### Handle bootloader, bootfile.audio, and bootfile.video
	$(QUIET) if [ '$(install_bootloader)' = 1 ] && [ -f packages/$(TARGET)/bootloader.tar ]; then cp packages/$(TARGET)/bootloader.tar tmp/pkgfile/$(TARGET)/; fi
	$(QUIET) if [ '$(install_bootloader)' = 1 ] && [ -f packages/$(TARGET)/bootloader_lk.tar ]; then cp packages/$(TARGET)/bootloader_lk.tar tmp/pkgfile/$(TARGET)/; fi

	$(QUIET) if [ -f $(CUSTOMER_FOLDER)/bootfile.video ] && [ -f $(CUSTOMER_FOLDER)/bootfile.image ]; then \
		echo "bootfile.image and bootfile.video cannot be co-existed !"; \
		exit 1; \
	fi
	$(QUIET) if [ -f $(CUSTOMER_FOLDER)/bootfile.audio ] && [ $(install_avfile_count) -gt 0 ]; then \
            cp $(CUSTOMER_FOLDER)/bootfile.audio tmp/pkgfile/$(TARGET)/; \
	fi
	$(QUIET) if [ -f $(CUSTOMER_FOLDER)/bootfile.video ] && [ $(install_avfile_count) -gt 0 ]; then \
            cp $(CUSTOMER_FOLDER)/bootfile.video tmp/pkgfile/$(TARGET)/; \
	fi
	$(QUIET) if [ '$(VMX)' = y ]; then \
		if [ -f $(CUSTOMER_FOLDER)/bootfile_vmx.image ] && [ $(install_avfile_count) -gt 0 ]; then \
           		cp $(CUSTOMER_FOLDER)/bootfile_vmx.image tmp/pkgfile/$(TARGET)/; \
		fi \
	else \
		if [ -f $(CUSTOMER_FOLDER)/bootfile.image ] && [ $(install_avfile_count) -gt 0 ]; then \
			if [ '$(NAS_IMGS)' = 'y' ] && [ '$(LAYOUT)' = 'nand' ]; then \
				$(LZMA_PATH) e $(CUSTOMER_FOLDER)/bootfile.image tmp/pkgfile/$(TARGET)/bootfile.lzma; \
			else \
           		cp $(CUSTOMER_FOLDER)/bootfile.image tmp/pkgfile/$(TARGET)/; \
			fi; \
		fi \
	fi
########for test##########
	dd if=/dev/zero of=tmp/pkgfile/$(TARGET)/pcpu.$(LAYOUT).bin bs=1K count=2;
########for test end###########
.PHONY: secure_case
secure_case: secure_check
	$(QUIET) if [ '$(LAYOUT)' = 'spi' ]; then \
		if [ '$(NAS_IMGS)' = 'y' ]; then \
			cd tmp && \
			$(GZIP_PATH) -9 $(LAYOUT).uImage && mv $(LAYOUT).uImage.gz pkgfile/$(TARGET)/$(LAYOUT).uImage; \
			$(LZMA_PATH) e $(AUDIO_FILE) pkgfile/$(TARGET)/$(AUDIO_FILE); \
			$(LZMA_PATH) e rescue.root.$(LAYOUT).cpio.gz_pad.img pkgfile/$(TARGET)/rescue.root.$(LAYOUT).cpio.gz_pad.img$(F_EXT); \
			cd -; \
		fi; \
	fi
	
	$(QUIET) if [ '$(LAYOUT)' = 'nand' ]; then \
		cd tmp && \
		if [ '$(SECURE_BOOT)' = y ]; then \
			if [ ! -f $(SECURE_KEY_FILE) ] || [ ! -f $(RSA_FW_PRIVATE_KEY) ]; then \
				echo "We cannot find the keys!"; \
				exit 1; \
			fi; \
			$(foreach file,$(ANDROID_FILES), \
				$(DO_SHA256_PATH) $(file) $(file)_padding.bin $(file)_signature.bin; \
				cat $(file) $(file)_padding.bin > $(file)_padding_final.bin; \
				$(call hwrsa-sign64, $(RSA_FW_PRIVATE_KEY), $(file)_signature.bin, $(file)_signature_enc.bin); \
				$(RTSSL_PATH) enc -e -aes_128_ecb -k `hexdump -e '8/1 "%02x"' $(SECURE_KEY_FILE)` -i $(file)_padding_final.bin \
														-o $(file)_aes_tmp.bin; \
				cat $(file)_aes_tmp.bin $(file)_signature_enc.bin > $(file).aes; \
				cp $(file).aes pkgfile/$(TARGET); \
			) \
			if [ '$(DTB_ENC)' = 'y' ]; then \
				$(foreach file,$(DTB_FILES), \
					$(DO_SHA256_PATH) $(file) $(file)_padding.bin $(file)_signature.bin; \
					cat $(file) $(file)_padding.bin > $(file)_padding_final.bin; \
					$(call hwrsa-sign64, $(RSA_FW_PRIVATE_KEY), $(file)_signature.bin, $(file)_signature_enc.bin); \
					$(RTSSL_PATH) enc -e -aes_128_ecb -k `hexdump -e '8/1 "%02x"' $(SECURE_KEY_FILE)` -i $(file)_padding_final.bin \
														-o $(file)_aes_tmp.bin; \
					cat $(file)_aes_tmp.bin $(file)_signature_enc.bin > $(file).aes; \
					cp $(file).aes pkgfile/$(TARGET); \
				) \
			fi; \
			cp pkgfile/$(TARGET)/$(LAYOUT).uImage$(F_EXT).aes pkgfile/$(TARGET)/$(LAYOUT).uImage2$(F_EXT).aes; \
			cp pkgfile/$(TARGET)/rescue.root.$(LAYOUT).cpio.gz_pad.img.aes pkgfile/$(TARGET)/rescue.root2.$(LAYOUT).cpio.gz_pad.img.aes; \
			cp $(AUDIO_FILE) pkgfile/$(TARGET)/$(AUDIO_FILE); \
			cp $(AUDIO_FILE) pkgfile/$(TARGET)/$(AUDIO_FILE2); \
			if [ '$(DTB_ENC)' = 'y' ]; then \
				cp pkgfile/$(TARGET)/rescue.$(LAYOUT).dtb.aes pkgfile/$(TARGET)/rescue2.$(LAYOUT).dtb.aes; \
			else \
				cp pkgfile/$(TARGET)/rescue.$(LAYOUT).dtb pkgfile/$(TARGET)/rescue2.$(LAYOUT).dtb; \
			fi; \
			if [ '$(TEE_FW)' = 'y' ]; then \
				cp tee_enc.bin pkgfile/$(TARGET)/tee_enc.bin.aes; \
				cp bl31_enc.bin pkgfile/$(TARGET)/bl31_enc.bin.aes; \
			fi; \
			if [ -f uboot.bin ]; then \
				cp uboot.bin pkgfile/$(TARGET); \
			fi; \
		fi; \
		if [ '$(NAS_IMGS)' != 'y' ] && [ '$(SQUASHFS_ROOT)' = 'y' ]; then \
			if [ '$(SECURE_BOOT)' != 'y' ]; then \
				cp $(LAYOUT).uImage$(F_EXT) $(AUDIO_FILE) android.root.$(LAYOUT).cpio.gz_pad.img rescue.root.$(LAYOUT).cpio.gz_pad.img pkgfile/$(TARGET); \
			fi; \
		else \
			mv -f $(TMP)/$(ETC_IMG_NAME) $(TMP)/pkgfile/$(TARGET)/; \
			if [ '$(SECURE_BOOT)' != 'y' ]; then \
				cp $(LAYOUT).uImage$(F_EXT) $(AUDIO_FILE) android.root.$(LAYOUT).cpio.gz_pad.img rescue.root.$(LAYOUT).cpio.gz_pad.img pkgfile/$(TARGET); \
			fi; \
			if [ '$(TEE_FW)' = 'y' ] && [ '$(VMX)' = 'n' ]; then \
				if [ '$(SECURE_BOOT)' != 'y' ]; then \
					cp tee.bin pkgfile/$(TARGET); \
					cp bl31.bin pkgfile/$(TARGET); \
					cp tee_enc.bin pkgfile/$(TARGET); \
					cp bl31_enc.bin pkgfile/$(TARGET); \
				fi; \
			fi; \
		fi; \
		if [ '$(SECURE_BOOT)' != 'y' ]; then \
			cp pkgfile/$(TARGET)/$(LAYOUT).uImage$(F_EXT) pkgfile/$(TARGET)/gold.$(LAYOUT).uImage$(F_EXT); \
			cp pkgfile/$(TARGET)/$(AUDIO_FILE) pkgfile/$(TARGET)/gold.$(AUDIO_FILE); \
			cp pkgfile/$(TARGET)/rescue.$(LAYOUT).dtb pkgfile/$(TARGET)/gold.rescue.$(LAYOUT).dtb; \
			cp pkgfile/$(TARGET)/rescue.root.$(LAYOUT).cpio.gz_pad.img pkgfile/$(TARGET)/gold.rescue.root.$(LAYOUT).cpio.gz_pad.img; \
		fi; \
	fi

	$(QUIET) if [ '$(LAYOUT)' = 'emmc' ] || [ '$(LAYOUT)' = 'sata' ]; then \
		cd tmp && \
		if [ '$(SECURE_BOOT)' = 'y' ] && [ '$(VMX)' = 'n' ]; then \
			if [ ! -f $(SECURE_KEY3_FILE) ] || [ ! -f $(RSA_FW_PRIVATE_KEY) ]; then \
				echo "We cannot find the keys!"; \
				exit 1; \
			fi; \
			$(foreach file,$(ANDROID_FILES), \
				$(DO_SHA256_PATH) $(file) $(file)_padding.bin $(file)_signature.bin;rm $(file)_padding.bin; \
				$(call hwrsa-sign-npinv64, $(RSA_FW_PRIVATE_KEY), $(file)_signature.bin, $(file)_signature_enc.bin); \
				$(OPENSSL) enc -e -aes-128-ecb -K `hexdump -e '16/1 "%02x"' $(SECURE_KEY3_FILE)` -nopad -in $(file) -out $(file)_aes_tmp.bin; \
				cat $(file)_aes_tmp.bin $(file)_signature_enc.bin > $(file).aes; \
				cp $(file).aes pkgfile/$(TARGET); \
			) \
			if [ '$(ANDROID_BRANCH)' != 'android-9' ]; then \
				if [ '$(DTB_ENC)' = 'y' ]; then \
					$(foreach file,$(DTB_FILES), \
						$(DO_SHA256_PATH) $(file) $(file)_padding.bin $(file)_signature.bin; rm $(file)_padding.bin; \
						$(call hwrsa-sign-npinv64, $(RSA_FW_PRIVATE_KEY), $(file)_signature.bin, $(file)_signature_enc.bin); \
						$(OPENSSL) enc -e -aes-128-ecb -K `hexdump -e '16/1 "%02x"' $(SECURE_KEY3_FILE)` -nopad -in $(file) -out $(file)_aes_tmp.bin; \
						cat $(file)_aes_tmp.bin $(file)_signature_enc.bin > $(file).aes; \
						cp $(file).aes pkgfile/$(TARGET); \
					) \
				fi; \
			fi; \
			cp $(AUDIO_FILE) pkgfile/$(TARGET)/$(AUDIO_FILE); \
			if [ '$(TEE_FW)' = 'y' ]; then \
				cp tee_enc.bin pkgfile/$(TARGET)/tee_enc.bin.aes; \
				cp bl31_enc.bin pkgfile/$(TARGET)/bl31_enc.bin.aes; \
				if [ '$(enable_ab_system)' = 'y' ]; then \
					cp lk_ab.bin pkgfile/$(TARGET); \
				fi; \
			fi; \
			if [ -f uboot.bin ]; then \
				cp uboot.bin pkgfile/$(TARGET); \
			fi; \
		else \
			if [ '$(TEE_FW)' = 'y' ] && [ '$(VMX)' = 'n' ]; then \
				cp tee.bin pkgfile/$(TARGET); \
				cp bl31.bin pkgfile/$(TARGET); \
				cp tee_enc.bin pkgfile/$(TARGET); \
				cp bl31_enc.bin pkgfile/$(TARGET); \
				if [ '$(enable_ab_system)' = 'y' ]; then \
					cp lk_ab.bin pkgfile/$(TARGET); \
				fi; \
			fi; \
			if [ '$(ANDROID_BRANCH)' = 'android-9' ]; then \
				cp $(AUDIO_FILE) pkgfile/$(TARGET); \
				cp bootimg.bin recoveryimg.bin pkgfile/$(TARGET)/; \
			else \
				cp $(LAYOUT).uImage$(F_EXT) $(AUDIO_FILE) pkgfile/$(TARGET); \
				if [ '$(DUAL_BOOT)' != 'y' ]; then \
					if [ '$(VMX)' = 'y' ]; then \
						cp android.root.$(LAYOUT).cpio.gz_pad.img pkgfile/$(TARGET); \
						if [ '$(VMX_TYPE)' = 'ultra' ]; then \
							cp rescue.root.$(LAYOUT).cpio.gz_pad.img.vmx.ultra pkgfile/$(TARGET)/rescue.root.$(LAYOUT).cpio.gz_pad.img; \
						else \
							cp rescue.root.$(LAYOUT).cpio.gz_pad.img.vmx pkgfile/$(TARGET)/rescue.root.$(LAYOUT).cpio.gz_pad.img; \
						fi; \
						cp pkgfile/$(TARGET)/$(LAYOUT).uImage$(F_EXT) pkgfile/$(TARGET)/rescue.$(LAYOUT).uImage$(F_EXT); \
						cp pkgfile/$(TARGET)/bluecore.audio$(F_EXT) pkgfile/$(TARGET)/rescue.bluecore.audio$(F_EXT); \
					else \
						cp android.root.$(LAYOUT).cpio.gz_pad.img rescue.root.$(LAYOUT).cpio.gz_pad.img pkgfile/$(TARGET); \
					fi; \
				fi; \
			fi; \
			if [ -f uboot.bin ]; then \
				cp uboot.bin pkgfile/$(TARGET); \
			fi; \
		fi; \
		if [ '$(SECURE_BOOT)' == y ]; then \
			echo "Secure boot is not support fastboot mode."; \
		else \
			dd if=/dev/zero of=kernel-20m bs=1M count=20; \
			dd if=$(LAYOUT).uImage of=kernel-20m conv=notrunc; \
			cat kernel-20m  rescue.$(LAYOUT).dtb > kernel-dtb; \
			mkbootimg --kernel kernel-dtb --ramdisk rescue.root.$(LAYOUT).cpio.gz_pad.img --second $(AUDIO_FILE) -o pkgfile/$(TARGET)/rescue.boot.img; \
			rm kernel-20m; rm kernel-dtb; \
		fi; \
		if [ '$(ANDROID_IMGS)' = 'y' ]; then \
			echo "Start copying ext4fs images ....."; \
		elif [ '$(LNX_IMGS)' = 'y' ]; then \
			echo "Start copying ext4fs images ....."; \
			if [ '$(ROOTFS_TYPE)' = 'ext4fs' ]; then \
				cp $(TMP)/$(EXT4FS_ROOTFSIMG) $(TMP)/pkgfile/$(TARGET)/; \
			fi; \
		fi; \
	fi

.PHONY: secure_check
secure_check:
	$(QUIET) if [ '$(rpmb_fw)' = 1 ]; then \
		if [ ! -f $(RPMB__FILE_PATH) ]; then \
			echo "We cannot find RPMB fw! (rpmb_programmer.bin)"; \
			exit 1; \
		fi; \
	fi
	
.PHONY: enableVMX
enableVMX:
	$(QUIET) if [ '$(LAYOUT)' = 'emmc' ] || [ '$(LAYOUT)' = 'sata' ]; then \
		cd tmp && \
		if [ '$(VMX)' = 'y' ]; then \
			if [ '$(SECURE_BOOT)' = 'y' ]; then \
				if [ '$(VMX_TYPE)' != 'ultra' ]; then \
					if [ ! -f $(VMX_AES_KEY) ] || [ ! -f $(VMX_RSA_EMBED_BL_PRIVATE_KEY) ]; then \
						echo "We cannot find the vmx keys!"; \
						exit 1; \
					fi; \
				else \
					if [ ! -f $(RSA_FW_PRIVATE_KEY) ] || [ ! -f $(RSA_TEE_PRIVATE_KEY) ] || [ ! -f $(AES_SCK_PATH) ] || [ ! -f $(AES_VENDOR_ID_PATH) ] || [ ! -f $(AES_MODULE_ID_PATH) ]; then \
						echo "We cannot find the vmx ultra related keys!"; \
						exit 1; \
					fi; \
				fi; \
			fi; \
			\
			if [ '$(VMX_TYPE)' = 'ultra' ]; then \
				cp $(CURDIR)/packages/$(PACKAGES)/lk_ultra.bin $(TMP)/pkgfile/$(PACKAGES)/lk.bin || exit 1; \
				cp $(CURDIR)/packages/$(PACKAGES)/tee_ultra.bin $(TMP)/pkgfile/$(PACKAGES)/tee.bin || exit 1; \
				cp $(CURDIR)/packages/$(PACKAGES)/bl31_ultra.bin $(TMP)/pkgfile/$(PACKAGES)/bl31.bin || exit 1; \
				cp $(CURDIR)/packages/$(PACKAGES)/rescue.lk_ultra.bin $(TMP)/pkgfile/$(PACKAGES)/rescue.lk.bin || exit 1; \
			else \
				cp $(CURDIR)/packages/$(PACKAGES)/lk.bin $(TMP)/pkgfile/$(PACKAGES)/lk.bin || exit 1; \
				cp $(CURDIR)/packages/$(PACKAGES)/tee.bin $(TMP)/pkgfile/$(PACKAGES)/tee.bin || exit 1; \
				cp $(CURDIR)/packages/$(PACKAGES)/bl31.bin $(TMP)/pkgfile/$(PACKAGES)/bl31.bin || exit 1; \
				cp $(CURDIR)/packages/$(PACKAGES)/rescue.lk.bin $(TMP)/pkgfile/$(PACKAGES)/rescue.lk.bin || exit 1; \
				cp $(CURDIR)/packages/$(PACKAGES)/rescue.tee.bin $(TMP)/pkgfile/$(PACKAGES)/rescue.tee.bin || exit 1; \
				cp $(CURDIR)/packages/$(PACKAGES)/rescue.bl31.bin $(TMP)/pkgfile/$(PACKAGES)/rescue.bl31.bin || exit 1; \
			fi ; \
			\
			cd $(TMP)/pkgfile/$(PACKAGES)/; \
			if [ '$(VMX_TYPE)' = 'ultra' ]; then \
				$(GEN_MARKET_ID) $(RESCUE_VERSION) $(RESCUE_VERSION_BIN) || exit 1; \
				$(GEN_MARKET_ID) $(NORMAL_VERSION) $(NORMAL_VERSION_BIN) || exit 1; \
				$(GEN_MARKET_ID) $(TRUST_VERSION) $(TRUST_VERSION_BIN) || exit 1; \
				$(GEN_MARKET_ID) $(MARKET_ID) $(MARKET_ID_BIN) || exit 1; \
				\
				cat rescue.lk.bin rescue.$(LAYOUT).uImage rescue.$(LAYOUT).dtb \
					rescue.root.$(LAYOUT).cpio.gz_pad.img > rescue_fws_temp.bin; \
				dd if=/dev/zero of=./rescue_zero.padding \
					bs=`expr 4 - \`stat -c %s rescue_fws_temp.bin\` % 4` count=1; \
				cat rescue_fws_temp.bin rescue_zero.padding $(RESCUE_VERSION_BIN) $(MARKET_ID_BIN) > rescue_fws.bin; \
				rm  rescue_fws_temp.bin rescue_zero.padding; \
				cat lk.bin $(LAYOUT).uImage android.$(LAYOUT).dtb \
					android.root.$(LAYOUT).cpio.gz_pad.img > normal_fws_temp.bin; \
				dd if=/dev/zero of=./normal_zero.padding \
					bs=`expr 4 - \`stat -c %s normal_fws_temp.bin\` % 4` count=1; \
				cat normal_fws_temp.bin normal_zero.padding $(NORMAL_VERSION_BIN) $(MARKET_ID_BIN) > normal_fws.bin; \
				rm  normal_fws_temp.bin normal_zero.padding; \
				cat tee.bin bl31.bin $(AUDIO_FILE) $(TRUST_VERSION_BIN) $(MARKET_ID_BIN) > trust_fws.bin; \
				\
				rm $(NORMAL_VERSION_BIN) $(RESCUE_VERSION_BIN) $(TRUST_VERSION_BIN) $(MARKET_ID_BIN); \
				\
				mv rescue_fws.bin rescue_boot_area.bin; \
				mv normal_fws.bin normal_boot_area.bin; \
				mv trust_fws.bin trust_boot_area.bin; \
				if [ '$(SECURE_BOOT)' = 'y' ]; then \
					mv rescue_boot_area.bin rescue_boot_area.bin.aes; \
					mv normal_boot_area.bin normal_boot_area.bin.aes; \
				fi; \
				mv trust_boot_area.bin trust_boot_area.bin.aes; \
				\
				if [ -f $(CURDIR)/packages/$(TARGET)/bootfile_vmx.image ] && [ $(install_avfile_count) -gt 0 ]; then \
					echo "fw = imageFile $(TARGET)/bootfile_vmx.image $(BOOTFILE_IMAGE_ADDR)" \
						"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/bootfile_vmx.image\``" >> $(TMP)/pkgfile/config.txt; \
				fi; \
				\
				echo "fw = rescueLK $(TARGET)/rescue.lk.bin $(LK_ADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/rescue.lk.bin\``" >> $(TMP)/pkgfile/config.txt; \
				echo "fw = rescueKernel $(TARGET)/rescue.$(LAYOUT).uImage $(LINUXADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/rescue.$(LAYOUT).uImage\``" >> $(TMP)/pkgfile/config.txt; \
				echo "fw = rescueDT $(TARGET)/rescue.$(LAYOUT).dtb $(RESCUEDT_ADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/rescue.$(LAYOUT).dtb\``" >> $(TMP)/pkgfile/config.txt; \
				echo "fw = rescueRootFS $(TARGET)/rescue.root.$(LAYOUT).cpio.gz_pad.img $(RESCUEROOTFSADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/rescue.root.$(LAYOUT).cpio.gz_pad.img\``" >> $(TMP)/pkgfile/config.txt; \
				\
				echo "fw = LK $(TARGET)/lk.bin $(LK_ADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/lk.bin\``" >> $(TMP)/pkgfile/config.txt; \
				echo "fw = linuxKernel $(TARGET)/$(LAYOUT).uImage $(LINUXADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/$(LAYOUT).uImage\``" >> $(TMP)/pkgfile/config.txt; \
				echo "fw = kernelDT $(TARGET)/android.$(LAYOUT).dtb $(KERNELDT_ADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/android.$(LAYOUT).dtb\``" >> $(TMP)/pkgfile/config.txt; \
				echo "fw = kernelRootFS $(TARGET)/android.root.$(LAYOUT).cpio.gz_pad.img $(KERNELROOTFSADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/android.root.$(LAYOUT).cpio.gz_pad.img\``" >> $(TMP)/pkgfile/config.txt; \
				echo "BL31 0x0 $(BL31ADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/bl31.bin\``" >> $(TMP)/pkgfile/trust_fw_config.txt; \
				echo "tee 0x1 $(TEEADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/tee.bin\``" >> $(TMP)/pkgfile/trust_fw_config.txt; \
				echo "audioKernel 0x2 $(AUDIOADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/$(AUDIO_FILE)\``" >> $(TMP)/pkgfile/trust_fw_config.txt; \
				rm lk.bin bluecore.audio tee.bin bl31.bin $(LAYOUT).uImage android.$(LAYOUT).dtb android.root.$(LAYOUT).cpio.gz_pad.img; \
				rm rescue.lk.bin rescue.bluecore.audio rescue.$(LAYOUT).uImage rescue.$(LAYOUT).dtb rescue.root.$(LAYOUT).cpio.gz_pad.img;\
				cd $(TMP); \
				$(GEN_TRUST_FW_TABLE) $(TRUST_VERSION) $(TMP)/pkgfile/trust_fw_config.txt $(TMP)/pkgfile/$(PACKAGES)/trust_fw_tbl.bin || exit 1; \
			else \
				$(GEN_MARKET_ID) $(RESCUE_VERSION) $(RESCUE_VERSION_BIN) || exit 1; \
				$(GEN_MARKET_ID) $(NORMAL_VERSION) $(NORMAL_VERSION_BIN) || exit 1; \
				$(GEN_MARKET_ID) $(MARKET_ID) $(MARKET_ID_BIN) || exit 1; \
				\
				cat rescue.lk.bin rescue.bluecore.audio rescue.tee.bin rescue.bl31.bin rescue.$(LAYOUT).uImage rescue.$(LAYOUT).dtb \
					rescue.root.$(LAYOUT).cpio.gz_pad.img $(RESCUE_VERSION_BIN) $(MARKET_ID_BIN) > rescue_fws.bin; \
				cat lk.bin bluecore.audio tee.bin bl31.bin $(LAYOUT).uImage android.$(LAYOUT).dtb android.root.$(LAYOUT).cpio.gz_pad.img \
					$(NORMAL_VERSION_BIN) $(MARKET_ID_BIN) > normal_fws.bin; \
				cp bluecore.audio install_bluecore.audio; \
				\
				rm $(NORMAL_VERSION_BIN) $(RESCUE_VERSION_BIN) $(MARKET_ID_BIN); \
				\
				$(DO_SHA256_PATH) rescue_fws.bin rescue_fws_padding.bin rescue_fws_dgst.bin; \
				cat rescue_fws.bin rescue_fws_padding.bin > rescue_boot_area.bin; \
				$(DO_SHA256_PATH) normal_fws.bin normal_fws_padding.bin normal_fws_digest.bin; \
				cat normal_fws.bin normal_fws_padding.bin > normal_boot_area.bin; \
				if [ '$(SECURE_BOOT)' = 'y' ]; then \
					mv rescue_boot_area.bin rescue_boot_area.bin.aes; \
					mv normal_boot_area.bin normal_boot_area.bin.aes; \
				fi; \
				\
				if [ -f $(CURDIR)/packages/$(TARGET)/bootfile_vmx.image ] && [ $(install_avfile_count) -gt 0 ]; then \
					echo "fw = imageFile $(TARGET)/bootfile_vmx.image $(BOOTFILE_IMAGE_ADDR)" \
						"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/bootfile_vmx.image\``" >> $(TMP)/pkgfile/config.txt; \
				fi; \
				if [ '$(SECURE_BOOT)' = 'y' ]; then \
					echo "fw = rescueArea $(TARGET)/rescue_boot_area.bin.aes $(RESCUE_AREA_ADDR)" \
						"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/rescue_boot_area.bin.aes\``" >> $(TMP)/pkgfile/config.txt; \
					echo "fw = normalArea $(TARGET)/normal_boot_area.bin.aes $(NORMAL_AREA_ADDR)" \
						"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/normal_boot_area.bin.aes\``" >> $(TMP)/pkgfile/config.txt; \
				else \
					echo "fw = rescueArea $(TARGET)/rescue_boot_area.bin $(RESCUE_AREA_ADDR)" \
						"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/rescue_boot_area.bin\``" >> $(TMP)/pkgfile/config.txt; \
					echo "fw = normalArea $(TARGET)/normal_boot_area.bin $(NORMAL_AREA_ADDR)" \
						"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/normal_boot_area.bin\``" >> $(TMP)/pkgfile/config.txt; \
				fi; \
				\
				echo "fw = rescueLK $(TARGET)/rescue.lk.bin $(LK_ADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/rescue.lk.bin\``" >> $(TMP)/pkgfile/config.txt; \
				echo "fw = rescueAudio $(TARGET)/rescue.bluecore.audio $(AUDIOADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/rescue.bluecore.audio\``" >> $(TMP)/pkgfile/config.txt; \
				echo "fw = rescueTEE $(TARGET)/rescue.tee.bin $(TEEADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/rescue.tee.bin\``" >> $(TMP)/pkgfile/config.txt; \
				echo "fw = rescueBL31 $(TARGET)/rescue.bl31.bin $(BL31ADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/rescue.bl31.bin\``" >> $(TMP)/pkgfile/config.txt; \
				echo "fw = rescueKernel $(TARGET)/rescue.$(LAYOUT).uImage $(LINUXADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/rescue.$(LAYOUT).uImage\``" >> $(TMP)/pkgfile/config.txt; \
				echo "fw = rescueDT $(TARGET)/rescue.$(LAYOUT).dtb $(RESCUEDT_ADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/rescue.$(LAYOUT).dtb\``" >> $(TMP)/pkgfile/config.txt; \
				echo "fw = rescueRootFS $(TARGET)/rescue.root.$(LAYOUT).cpio.gz_pad.img $(RESCUEROOTFSADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/rescue.root.$(LAYOUT).cpio.gz_pad.img\``" >> $(TMP)/pkgfile/config.txt; \
				\
				echo "fw = LK $(TARGET)/lk.bin $(LK_ADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/lk.bin\``" >> $(TMP)/pkgfile/config.txt; \
				echo "fw = audioKernel $(TARGET)/bluecore.audio $(AUDIOADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/bluecore.audio\``" >> $(TMP)/pkgfile/config.txt; \
				echo "fw = tee $(TARGET)/tee.bin $(TEEADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/tee.bin\``" >> $(TMP)/pkgfile/config.txt; \
				echo "fw = BL31 $(TARGET)/bl31.bin $(BL31ADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/bl31.bin\``" >> $(TMP)/pkgfile/config.txt; \
				echo "fw = linuxKernel $(TARGET)/$(LAYOUT).uImage $(LINUXADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/$(LAYOUT).uImage\``" >> $(TMP)/pkgfile/config.txt; \
				echo "fw = kernelDT $(TARGET)/android.$(LAYOUT).dtb $(KERNELDT_ADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/android.$(LAYOUT).dtb\``" >> $(TMP)/pkgfile/config.txt; \
				echo "fw = kernelRootFS $(TARGET)/android.root.$(LAYOUT).cpio.gz_pad.img $(KERNELROOTFSADDR)" \
					"0x`printf '%X' \`stat -c %s $(TMP)/pkgfile/$(PACKAGES)/android.root.$(LAYOUT).cpio.gz_pad.img\``" >> $(TMP)/pkgfile/config.txt; \
				rm lk.bin bluecore.audio tee.bin bl31.bin $(LAYOUT).uImage android.$(LAYOUT).dtb android.root.$(LAYOUT).cpio.gz_pad.img; \
				rm rescue.lk.bin rescue.bluecore.audio rescue.tee.bin rescue.bl31.bin rescue.$(LAYOUT).uImage rescue.$(LAYOUT).dtb rescue.root.$(LAYOUT).cpio.gz_pad.img;\
				rm normal_fws* rescue_fws*; \
				cd $(TMP); \
			fi ;\
		fi; \
	fi

clean:
	rm -rf tmp/ ./gen_binary/complete