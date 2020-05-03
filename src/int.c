/* 中断相关 */

#include "bootpack.h"

#define PORT_KEYDAT 0x0060

void init_pic(void)
/* PIC初始化*/
{
	io_out8(PIC0_IMR, 0xff); /* 禁用0x0021所有中断 */
	io_out8(PIC1_IMR, 0xff); /* 禁用0x00a1所有中断*/

	io_out8(PIC0_ICW1, 0x11);	/* 边沿触发模式 */
	io_out8(PIC0_ICW2, 0x20);	/* IRQ0-7由INT20-27接收*/
	io_out8(PIC0_ICW3, 1 << 2); /* PIC1由IRQ2链接 */
	io_out8(PIC0_ICW4, 0x01);	/* 无缓冲区模式 */

	io_out8(PIC1_ICW1, 0x11); /* 边沿触发模式 */
	io_out8(PIC1_ICW2, 0x28); /* IRQ8-5由INT28-2f接收*/
	io_out8(PIC1_ICW3, 2);	  /* PIC1由IRQ2链接  */
	io_out8(PIC1_ICW4, 0x01); /* 无缓冲区模式 */

	io_out8(PIC0_IMR, 0xfb); /* 11111011 PIC1以外的中断全部禁止 */
	io_out8(PIC1_IMR, 0xff); /* 11111111 禁用所有中断*/

	return;
}

void inthandler21(int *esp)
/* 从PS / 2键盘中断 */
{
	struct BOOTINFO *binfo = (struct BOOTINFO *)ADR_BOOTINFO;

	unsigned char data, s[4];

	io_out8(PIC0_OCW2, 0x61);	/*通知PIC "IRQ-01"已经处理完毕 */ /*第二个参数是 IRQ-x, "0x60+x" 即可*/
	data = io_in8(PORT_KEYDAT);
	sprintf(s, "%02x", data);

	boxfill8(binfo->vram, binfo->scrnx, COL8_000000, 0, 16, 15, 31);
	putfonts8_asc(binfo->vram, binfo->scrnx, 0, 16, COL8_FFFFFF, s);
	
	return;
}

void inthandler2c(int *esp)
/* 从PS / 2鼠标中断 */
{
	struct BOOTINFO *binfo = (struct BOOTINFO *)ADR_BOOTINFO;
	boxfill8(binfo->vram, binfo->scrnx, COL8_000000, 0, 0, 32 * 8 - 1, 15);
	putfonts8_asc(binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, "INT 2C (IRQ-12) : PS/2 mouse");
	for (;;)
	{
		io_hlt();
	}
}

void inthandler27(int *esp)
{
	/*防止来自PIC0的不完整中断的措施 */
	/*在Athlon64X2机器上，由于芯片组的原因，在初始化PIC时此中断仅发生一次 */
	/*此中断处理功能对该中断不起作用 */
	/*您为什么不做任何事情？
	→该中断是由PIC初始化时的电气噪声产生的，
	您不必认真做任何事情。 
	*/
	io_out8(PIC0_OCW2, 0x67); /*通知PIC IRQ-07接受（请参阅7-1） */
	return;
}
