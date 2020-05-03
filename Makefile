TOOLPATH = ../../tool/
INCPATH  = $(TOOLPATH)haribote/
MAKE     = make -r
NASK     = $(TOOLPATH)nask.exe
CC1      = $(TOOLPATH)cc1.exe -I$(INCPATH) -Os -Wall -quiet
GAS2NASK = $(TOOLPATH)gas2nask.exe -a
OBJ2BIM  = $(TOOLPATH)obj2bim.exe
MAKEFONT = $(TOOLPATH)makefont.exe
BIN2OBJ  = $(TOOLPATH)bin2obj.exe
BIM2HRB  = $(TOOLPATH)bim2hrb.exe
RULEFILE = $(TOOLPATH)haribote/haribote.rul
EDIMG    = $(TOOLPATH)edimg.exe
IMGTOL   = $(TOOLPATH)imgtol.com
COPY     = cp
DEL      = rm -rf

DIST_DIR = dist/
NAS_DIR  = nas/
SRC_DIR	 = src/
RES_DIR  = res/

OBJS_BOOTPACK = $(DIST_DIR)naskfunc.bin \
				$(DIST_DIR)bootpack.obj \
				$(DIST_DIR)hankaku.obj \
				$(DIST_DIR)graphic.obj \
				$(DIST_DIR)dsctbl.obj \
				$(DIST_DIR)int.obj

$(DIST_DIR):
	rm -rf $(DIST_DIR)
	mkdir $(DIST_DIR)

# 根据 nas 构建基础bin
$(DIST_DIR)%.bin : $(NAS_DIR)%.nas $(DIST_DIR)
	$(NASK) $(NAS_DIR)$*.nas $(DIST_DIR)$*.bin $(DIST_DIR)$*.lst

# 根据 .c 文件构建obj
$(DIST_DIR)%.gas : $(SRC_DIR)%.c $(DIST_DIR)
	$(CC1) -o $(DIST_DIR)$*.gas $(SRC_DIR)$*.c

$(DIST_DIR)%.nas : $(DIST_DIR)%.gas
	$(GAS2NASK) $(DIST_DIR)$*.gas $(DIST_DIR)$*.nas

$(DIST_DIR)%.obj : $(DIST_DIR)%.nas
	$(NASK) $(DIST_DIR)$*.nas $(DIST_DIR)$*.obj $(DIST_DIR)$*.lst

# 构建字体
$(DIST_DIR)hankaku.bin : $(RES_DIR)hankaku.txt $(DIST_DIR)
	$(MAKEFONT) $(RES_DIR)hankaku.txt $(DIST_DIR)hankaku.bin

$(DIST_DIR)hankaku.obj : $(DIST_DIR)hankaku.bin
	$(BIN2OBJ) $(DIST_DIR)hankaku.bin $(DIST_DIR)hankaku.obj _hankaku


# 构建bootpack # 3MB+64KB=3136KB
$(DIST_DIR)bootpack.bim : $(OBJS_BOOTPACK) $(DIST_DIR)
	$(OBJ2BIM) @$(RULEFILE) out:$(DIST_DIR)bootpack.bim stack:3136k map:$(DIST_DIR)bootpack.map $(OBJS_BOOTPACK) 

$(DIST_DIR)bootpack.hrb : $(DIST_DIR)bootpack.bim 
	$(BIM2HRB) $(DIST_DIR)bootpack.bim $(DIST_DIR)bootpack.hrb 0


# 构建系统镜像
$(DIST_DIR)haribote.sys : $(DIST_DIR)asmhead.bin $(DIST_DIR)bootpack.hrb
	cat $(DIST_DIR)asmhead.bin $(DIST_DIR)bootpack.hrb > $(DIST_DIR)haribote.sys

$(DIST_DIR)haribote.img : $(DIST_DIR)ipl10.bin $(DIST_DIR)haribote.sys
	$(EDIMG)   \
		imgin:$(TOOLPATH)fdimg0at.tek \
		wbinimg src:$(DIST_DIR)ipl10.bin len:512 from:0 to:0 \
		copy from:$(DIST_DIR)haribote.sys to:@: \
		imgout:$(DIST_DIR)haribote.img


img :
	$(MAKE) $(DIST_DIR)haribote.img

run :
	$(MAKE) img
	$(COPY) $(DIST_DIR)haribote.img $(TOOLPATH)qemu/fdimage0.bin
	$(MAKE) -C $(TOOLPATH)qemu

clean :
	-$(DEL) *.bin
	-$(DEL) *.lst
	-$(DEL) *.obj
	-$(DEL) bootpack.map
	-$(DEL) bootpack.bim
	-$(DEL) bootpack.hrb
	-$(DEL) haribote.sys
	-$(DEL)	$(DIST_DIR)