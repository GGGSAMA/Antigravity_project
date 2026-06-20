import mido
from mido import Message, MidiFile, MidiTrack, MetaMessage
import os

def create_zen_aria(filename):
    mid = MidiFile()
    # 52 BPM
    tempo = mido.bpm2tempo(52)
    ticks_per_beat = mid.ticks_per_beat
    # 3/4 拍，每小节 3 拍
    measure_ticks = ticks_per_beat * 3
    
    t0 = MidiTrack()
    mid.tracks.append(t0)
    t0.append(MetaMessage('set_tempo', tempo=tempo))
    t0.append(MetaMessage('time_signature', numerator=3, denominator=4))
    
    # 提取哥德堡变奏曲 Aria 核心走向，转化为中式五声音阶（宫商角徵羽）
    # 大幅拉长时值，每小节只保留一个核心长音
    dongxiao_notes = [
        67, 64, 62, 59,  57, 59, 62, 55, # 前 8 小节
        55, 57, 59, 62,  64, 67, 69, 67, # 变奏铺垫
        71, 69, 67, 64,  62, 64, 67, 59, # 情绪微起
        59, 57, 55, 57,  59, 62, 64, 67  # 归于沉寂
    ] # 共 32 小节
    
    # Track 1: 洞箫主旋律 (MIDI 乐器编号 73: Flute)
    t_flute = MidiTrack()
    mid.tracks.append(t_flute)
    t_flute.append(Message('program_change', program=73, channel=0))
    for note in dongxiao_notes:
        t_flute.append(Message('note_on', note=note, velocity=60, time=0, channel=0))
        # 洞箫绵长气声，持续整整一小节
        t_flute.append(Message('note_off', note=note, velocity=64, time=measure_ticks, channel=0))

    # Track 2: 古筝打底分解和弦 (MIDI 乐器编号 107: Koto)
    t_guzheng = MidiTrack()
    mid.tracks.append(t_guzheng)
    t_guzheng.append(Message('program_change', program=107, channel=1))
    for i, note in enumerate(dongxiao_notes):
        base = note - 12 # 低一个八度
        if i % 2 == 0:
            # 极轻柔的拨弦
            t_guzheng.append(Message('note_on', note=base, velocity=35, time=0, channel=1))
            t_guzheng.append(Message('note_off', note=base, velocity=64, time=ticks_per_beat, channel=1))
            t_guzheng.append(Message('note_on', note=base+7, velocity=30, time=0, channel=1))
            t_guzheng.append(Message('note_off', note=base+7, velocity=64, time=ticks_per_beat, channel=1))
            t_guzheng.append(Message('note_on', note=base+12, velocity=25, time=0, channel=1))
            t_guzheng.append(Message('note_off', note=base+12, velocity=64, time=ticks_per_beat, channel=1))
        else:
            # 空拍留白
            t_guzheng.append(Message('note_off', note=0, velocity=0, time=measure_ticks, channel=1))

    # Track 3: 古琴低音衬底 (MIDI 乐器编号 104: Sitar 近似代替)
    t_guqin = MidiTrack()
    mid.tracks.append(t_guqin)
    t_guqin.append(Message('program_change', program=104, channel=2))
    for i in range(0, 32, 4):
        base = dongxiao_notes[i] - 24 # 低两个八度
        t_guqin.append(Message('note_on', note=base, velocity=45, time=0, channel=2))
        # 余音绕梁，持续四个小节
        t_guqin.append(Message('note_off', note=base, velocity=64, time=measure_ticks * 4, channel=2))
        
    # Track 4: 编钟空灵点缀 (MIDI 乐器编号 14: Tubular Bells)
    t_bianzhong = MidiTrack()
    mid.tracks.append(t_bianzhong)
    t_bianzhong.append(Message('program_change', program=14, channel=3))
    for i in range(0, 32, 8):
        bell_note = dongxiao_notes[i] + 12 # 高一个八度
        t_bianzhong.append(Message('note_on', note=bell_note, velocity=50, time=0, channel=3))
        # 极长延音，持续八个小节
        t_bianzhong.append(Message('note_off', note=bell_note, velocity=64, time=measure_ticks * 8, channel=3))

    # 尾段加长余韵留白 (添加4个小节的空拍)
    t_flute.append(Message('note_off', note=0, velocity=0, time=measure_ticks * 4, channel=0))

    mid.save(filename)
    print(f"MIDI 音乐已成功生成：{os.path.abspath(filename)}")

if __name__ == '__main__':
    create_zen_aria("goldberg_zen_meditation.mid")
