from PIL import Image, ImageDraw, ImageFont
import os

base = '/media/sf_shared/Lab2/Lab2_1/Sim'
actual = Image.open(base + '/Counter_tb_waveform.png').convert('RGB')
expected = Image.open(base + '/expected_waveform.png').convert('RGB')

W = actual.width
eh = round(expected.height * W / expected.width)
expected = expected.resize((W, eh), Image.LANCZOS)

fp_bold = '/usr/share/fonts/opentype/noto/NotoSerifCJK-Bold.ttc'
fp_reg = '/usr/share/fonts/opentype/noto/NotoSerifCJK-Regular.ttc'
if not os.path.exists(fp_reg):
    fp_reg = fp_bold
f_title = ImageFont.truetype(fp_bold, 30)
f_note = ImageFont.truetype(fp_reg, 20)

margin = 40
title_h = 48
gap = 28
note_lines = [
    '说明：实际图的时间轴是 0-340 ns（CNT_MAX=4，缩短计数）；预期图是 50 MHz、半周期 0.5 s 的示意。',
    '两者时间刻度不同，比较的是翻转顺序、cnt 递增/清零，以及复位后 LED 回到亮、计时从 0 重新开始。',
    '复位语义：讲义图用低有效 sys_rst_n；你的设计用 sys_rst（按下=0，松开=1，松开上升沿复位），功能等价。',
]
note_h = len(note_lines) * 28 + 16

H = margin + title_h + actual.height + gap + title_h + eh + gap + note_h + margin
img = Image.new('RGB', (W + 2 * margin, H), 'white')
d = ImageDraw.Draw(img)

y = margin
d.text((margin, y), '实际仿真波形（VCD -> CSV -> MATLAB，CNT_MAX=4）', font=f_title, fill=(20, 40, 80))
y += title_h
img.paste(actual, (margin, y))
y += actual.height

d.line([(margin, y + gap // 2), (margin + W, y + gap // 2)], fill=(180, 180, 180), width=2)
y += gap

d.text((margin, y), '讲义预期波形（50 MHz，半周期 0.5 s）', font=f_title, fill=(20, 40, 80))
y += title_h
img.paste(expected, (margin, y))
y += eh
y += gap

for line in note_lines:
    d.text((margin, y), line, font=f_note, fill=(60, 60, 60))
    y += 28

out = base + '/Counter_waveform_compare.png'
img.save(out)
print('saved', out, img.size)
