F10::

;===============================����========================================

;ϵͳ��ʱ
delayer := 50

;����ٶ�
SetDefaultMouseSpeed, 0

;��ʾ����
; CoordMode, ToolTip, Screen

;����ɨ�״���
WinWait, ɨ��
WinActivate, ɨ��

blocksize := 16
left_x := 16
top_y := 100
right_x := left_x + blocksize * 30
bottom_y := top_y + blocksize * 16
halfsize := blocksize // 2

;��ɫ����
color_to_num := {0xC0C0C0: 0, 0x0000FF: 1, 0x008000: 2, 0xFF0000: 3, 0x000080: 4, 0x800000: 5, 0x008080: 6, 0x000000: 7, 0x808080: 8}

;����ѭ��������
thirty := [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30]
sixteen := [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]

;��һ�����������
firstblock_x := left_x + halfsize
firstblock_y := top_y + halfsize


;=================================END=======================================


��ʼ�����: 
blocktable := {}
for r in sixteen {
    for c in thirty {    
        blocktable[r, c] := new Block(r, c)
    }
}

��һ��: ;�㿪�м��һ��
blocktable[1, 1].Open()


New: 
loop {
dealed := 0
for r in sixteen {
    for c in thirty {
        check_block := blocktable[r, c]
        if (check_block.num > 0) {
            if (not check_block.finalled) { 

                ; ����������Χ���ӵ�������û����block������
                flags := 0 
                close_block_num := 0
                close_blocks := []
                for i, block in SurrondingBlocks(check_block) {
                    if (block.openned == 0) {
                        close_block_num++
                        close_blocks.Insert(block)
                        if (block.flagged == 1) {
                            flags++
                        }
                    }
                }
                ; msgbox, % "��������" flags "`r�رյĸ�������" close_block_num "`r���֣�" check_block.num


                ;������������������֣���������Χ
                if (check_block.num == flags && flags < close_block_num) {
                    for i, block in close_blocks {
                        block.Open()
                        dealed++
                    }
                    check_block.finalled := True
                }

                ;���û���ĵ������������֣��Ͱ���Χ��������
                if (check_block.num == close_block_num && flags < close_block_num) {
                    for i, block in close_blocks {
                        block.Flag()
                        dealed++
                    }
                    check_block.finalled := True
                }
            }    
        }
    }
}
; msgbox, %dealed%
} Until dealed == 0


�ڶ���: ;�ҵ���Ե����block
edge_blocks := []
for r in sixteen {
    for c in thirty {  
        if (blocktable[r, c].num > 0 && (not blocktable[r, c].finalled)) {
            for i, block in SurrondingBlocks(blocktable[r, c]) {
                if (block.openned == 0 && block.flagged == 0) {
                    if (not IsIn(block, edge_blocks)) {
                        edge_blocks.Insert(block)
                    }
                }
            }                                
        }
    }
}

; û���˾ͽ���
if (edge_blocks == []) {
    Reload
}

������: ;������С�ĵ㿪

possible_panels := PossiblePanels(edge_blocks)
ToolTip
; progress, off

;�����ۼ�ÿ��block�����׵Ĵ���
counts := [] 
for step in possible_panels[1] {
    counts[step] := 0
}

for i, panel in possible_panels { ;������block�����׵Ĵ����ۼ�
    for step, mark in panel {
        counts[step] += mark
    }
}

did_flag := False
for step, marks in counts { ;�����block������panel�ж����ף�������
    if (marks == possible_panels.Length()) {
        step.Flag()
        did_flag := True
    }
}

;�����block������panel�ж�û�г��ֹ��ף��㿪
did_open := False
for step, marks in counts { 
    if (marks == 0) {
        step.Open()
        did_open := True
    }
}

;���û��һ�����԰�ȫ��block���Ե㿪���Ǿ͵㿪������С��
if ((not did_open) && (not did_flag)) { 
    ; msgbox, % "��Ե���ȣ�" edge_blocks.length() "`r�����ӣ�" did_flag "`r�򿪹���" did_open "`r��ʼ��"
    min_marks := possible_panels.Length() + 1 ;��ʼֵ����Ϊ��������ֵ��1
    for step, marks in counts {
    if (marks < min_marks) {
            min_marks := marks 
            min_marks_step := step ;�ҳ��׳��ִ������ٵ�һ��block
        }    
    } 
    min_marks_step.Open()

    ; �����û�в´��´��˾ͽ���
    PixelGetColor, Getcolor, min_marks_step.x - 6, min_marks_step.y - 6, RGB
    if (Getcolor == 0xFF0000) { 
        length := edge_blocks.length()
        MsgBox, 5, , Bad luck. 
        IfMsgBox, Retry 
        {
            Click 257, 75 ; ��Ц�����¿�ʼ
            Goto, ��ʼ�����
        }
        Reload
    }
}

Goto, New

;===============================�ӹ���======================================

PrintList(list1) {
    s := ""
    for i, v in list1 {
        s := s " " v
    }
    ToolTip, %s%, 960, 800, 1
}

PrintListOfList(list2) {
    l := "length: " list2.Length()
    for i, list1 in list2 {
        s := ""
        for i, v in list1 {
            s := s " " v
        }
        l := l "`r" s
    }
    ToolTip, %l%, 1300, 0, 2
}


class Block {
    __New(r, c) {
        this.r := r
        this.c := c
        this.x := xOfc(c)
        this.y := yOfr(r)
        this.flagged := 0
        this.openned := 0
        this.num := ""
        this.finalled := False
    }

    Open() {
        if (this.openned == 0 && this.flagged ==0) {
            Mousemove, this.x, this.y
            Click
            this.openned := 1
            if (this.num == "") { ;û�м������ֵĻ��ͼ��һ��
                PixelGetColor, Getcolor, this.x, this.y, RGB
                this.num := ColorToNum(Getcolor)
                if (this.num == 0) { ;����㿪�����ǿյģ��ͻ������
                    for i, block in SurrondingBlocks(this) {
                        block.Open()
                    }
                }
            }
        }   
    }

    Flag() {
        if (this.flagged == 0) {
            Mousemove, this.x, this.y
            Click Right
            this.flagged := 1
        }
    }

    MouseOn() {
        Mousemove, this.x, this.y
    }
}

ColorToNum(color1) {
    global color_to_num
    return color_to_num[color1]
}

LengthOfList(collection) {
    l := 0
    for i, v in collection{
        l++
    }
    return l
}

IsIn(item, collection){
    for i, v in collection{
        if (v == item) {
            return 1
        }
    }
    return 0
}

xOfc(c) { ; ��������x����
    global
    return (c - 1) * blocksize + firstblock_x
}

yOfr(r) { ; ��������y����
    global
    return (r - 1) * blocksize + firstblock_y
}


SurrondingBlocks(block) {
    global blocktable
    surrounding_blocks := []
    for i, small_r in [-1, 0, 1] {
        for i, small_c in [-1, 0, 1] {
            if (not (small_r == 0 and small_c == 0)) {
                real_r := block.r + small_r
                real_c := block.c + small_c
                if (real_r > 0 and real_r <= 16 and real_c >0 and real_c <= 30) {
                        surrounding_blocks.Insert(blocktable[real_r, real_c])
                }
            }
        }
    }
    return surrounding_blocks
}

PossiblePanels(blocks) {
    global edge_blocks
    if (blocks.Length() == 0) {
        return [[]]
    } else {
        new_possible_panels := []
        less_blocks := blocks.Clone()
        less_blocks.Remove()
        for n, panel in PossiblePanels(less_blocks) {
            reject0 := False ; ��ʼ�������ܾ�״̬
            reject1 := False

            ; blocks[panel.Length()+1].MouseOn()
            ; msgbox, �ߵ�������
            now_step := blocks[LengthOfList(panel)+1]
            for i, block in SurrondingBlocks(now_step) { ;�ߵ���ǰ��һ�飬������Χ8������
                if (block.num > 0) { ;�����ֵ�block(��������� && (not block.finalled)�� ����֪Ϊ�β���)

                    ; ����δ�㿪��block�����������ӵ���������ǹ���1��0������
                    close_block_num := 0
                    flags := 0
                    marked_zeros := 0 
                    marked_ones := 0
                    for i, block2 in SurrondingBlocks(block) { ;������Χ��block
                        if (block2.openned == 0) {
                            close_block_num++
                        }
                        if (block2.flagged == 1)
                            flags++
                        if (panel.HasKey(block2)) { ; ���������Χ��block��֮ǰ�߹���·����
                            if (panel[block2] == 1) {
                                marked_ones++
                            }
                            if (panel[block2] == 0) {
                                marked_zeros++
                            }
                        }
                    }
                    if (block.num == close_block_num - marked_zeros) { ;��������һ������������
                        reject0 := True                    
                    }
                    if (block.num == marked_ones + flags) { ;����������������������
                        reject1 := True 
                        ; block.MouseOn()
                        ; msgbox, % "·��" n " ���ھܾ�1`r" block.num " == " marked_ones
                    }
                }
            }

            if (not reject0) {
                ;blocks[panel.Length()+1].MouseOn()
                ;msgbox, ���ܾ�0
                panel0 := panel.Clone()
                panel0.Insert(now_step, 0)
                new_possible_panels.Insert(panel0)
            }
            if (not reject1) {
                ;blocks[panel.Length()+1].MouseOn()
                ;msgbox, ���ܾ�1
                panel1 := panel.Clone()
                panel1.Insert(now_step, 1)
                new_possible_panels.Insert(panel1) 
            }
            ; if (reject0 && reject1) {
            ;     msgbox, % "·��" n " ���������ܾ���"
            ; }
        }
        ;PrintListOfList(new_possible_panels)
        ToolTip, % "Step: " LengthOfList(new_possible_panels[1]) " / " edge_blocks.Length() "`rPossible panels found: " new_possible_panels.Length()
        ; progressee := new_possible_panels[1].Length() / edge_blocks.Length() * 100
        ; textee := "Steps: " new_possible_panels[1].Length() " / " edge_blocks.Length() "`rPossible panels found: " new_possible_panels.Length()
        ; Progress, %progressee%, %textee%, ,Processing...

        return new_possible_panels
    }
}


;=================================END=======================================

return

F11:: pause
F12:: Reload 
