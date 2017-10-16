F10::

;===============================����========================================

;ϵͳ��ʱ
delayer := 50

;����ٶ�
SetDefaultMouseSpeed, 0

;��ʾ����777
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
color_to_num := {0xC0C0C0: 0, 0x0000FF: 1, 0x008000: 2, 0xFF0000: 3, 0x000080: 4, 0x800000: 5}
white := 0xFFFFFF


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
blocktable[8, 15].open()


�ڶ���: ;�ҵ���Ե����block
edge_blocks := []
for r in sixteen {
    for c in thirty {  
        if (blocktable[r, c].num > 0) {
            for i, block in surrounding_blocks(blocktable[r, c]) {
                if (block.openned == 0 && block.flagged == 0) {
                    if (not isin(block, edge_blocks)) {
                        edge_blocks.insert(block)
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

possible_panels := possible_panels(edge_blocks)
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

for step, marks in counts { ;�����block������panel�ж����ף�������
    if (marks == possible_panels.length()) {
        edge_blocks[step].flag()
    }
}

;�����block������panel�ж�û�г��ֹ��ף��㿪
did_open := False
for step, marks in counts { 
    if (marks == 0) {
        edge_blocks[step].open()
        did_open := True
    }
}

;���û��һ�����԰�ȫ��block���Ե㿪���Ǿ͵㿪������С��
if (not did_open) { 
    min_marks := possible_panels.length() + 1 ;��ʼֵ����Ϊ��������ֵ��1
    for step, marks in counts {
    if (marks < min_marks) {
            min_marks := marks 
            min_marks_step := step ;�ҳ��׳��ִ������ٵ�һ��block
        }    
    } 
    edge_blocks[min_marks_step].open()

    ; �����û�в´��´��˾ͽ���
    PixelGetColor, Getcolor, edge_blocks[min_marks_step].x - 6, edge_blocks[min_marks_step].y - 6, RGB
    if (Getcolor == 0xFF0000) { 
        MsgBox, 5, , Bad luck.
        IfMsgBox, Retry 
        {
            Click 257, 75 ; ��Ц�����¿�ʼ
            Goto, ��ʼ�����
        }
        Reload
    }
}

Goto, �ڶ���

;===============================�ӹ���======================================

print_list(list1) {
    s := ""
    for i, v in list1 {
        s := s " " v
    }
    ToolTip, %s%, 960, 800, 1
}

print_list_of_list(list2) {
    l := "length: " list2.length()
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
        this.x := x_of_c(c)
        this.y := y_of_r(r)
        this.flagged := 0
        this.openned := 0
        this.num := ""
    }

    open() {
        if (this.openned == 0) {
            Mousemove, this.x, this.y
            Click
            this.openned := 1
            if (this.num == "") { ;û�м������ֵĻ��ͼ��һ��
                PixelGetColor, Getcolor, this.x, this.y, RGB
                this.num := ColorToNum(Getcolor)
                if (this.num == 0) { ;����㿪�����ǿյģ��ͻ������
                    for i, block in surrounding_blocks(this) {
                        block.open()
                    }
                }
            }
        }   
    }

    flag() {
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

isin(item, collection){
    for i, v in collection{
        if (v == item) {
            return 1
        }
    }
    return 0
}

x_of_c(c) { ; ��������x����
    global
    return (c - 1) * blocksize + firstblock_x
}

y_of_r(r) { ; ��������y����
    global
    return (r - 1) * blocksize + firstblock_y
}


surrounding_blocks(block) {
    global blocktable
    surrounding_blocks := []
    for i, small_r in [-1, 0, 1] {
        for i, small_c in [-1, 0, 1] {
            if (not (small_r == 0 and small_c == 0)) {
                real_r := block.r + small_r
                real_c := block.c + small_c
                if (real_r > 0 and real_r <= 16 and real_c >0 and real_c <= 30) {
                        surrounding_blocks.insert(blocktable[real_r, real_c])
                }
            }
        }
    }
    return surrounding_blocks
}

possible_panels(blocks) {
    global edge_blocks
    if (blocks.length() == 0) {
        return [[]]
    } else {
        new_possible_panels := []
        less_blocks := blocks.clone()
        less_blocks.remove()
        for n, panel in possible_panels(less_blocks) {
            reject0 := False ; ��ʼ�������ܾ�״̬
            reject1 := False

            ; blocks[panel.length()+1].MouseOn()
            ; msgbox, �ߵ�������
            for i, block in surrounding_blocks(blocks[panel.length()+1]) { ;�ߵ���ǰ��һ�飬������Χ8������
                if (block.num > 0) { ;�����ֵ�block

                    ; ����δ�㿪��block�����������ӵ�����
                    close_block_num := 0
                    flags := 0
                    for i, block2 in surrounding_blocks(block) { ;������Χ��block
                        if (block2.openned == 0) {
                            close_block_num++
                        }
                        if (block2.flagged == 1)
                            flags++
                    }
                    
                    ; �����Ѿ������1��0������
                    marked_zeros := 0 
                    marked_ones := 0
                    for block3, mark in panel {
                        if (isin(blocks[block3], surrounding_blocks(block))) {
                            if (mark == 1) {
                                marked_ones++
                            } else {
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
                ;blocks[panel.length()+1].MouseOn()
                ;msgbox, ���ܾ�0
                panel0 := panel.clone()
                panel0.insert(0)
                new_possible_panels.insert(panel0)
            }
            if (not reject1) {
                ;blocks[panel.length()+1].MouseOn()
                ;msgbox, ���ܾ�1
                panel1 := panel.clone()
                panel1.insert(1)
                new_possible_panels.insert(panel1) 
            }
            ; if (reject0 && reject1) {
            ;     msgbox, % "·��" n " ���������ܾ���"
            ; }
        }
        ;print_list_of_list(new_possible_panels)
        ToolTip, % "Step: " new_possible_panels[1].length() " / " edge_blocks.length() "`rPossible panels found: " new_possible_panels.length()
        ; progressee := new_possible_panels[1].length() / edge_blocks.length() * 100
        ; textee := "Steps: " new_possible_panels[1].length() " / " edge_blocks.length() "`rPossible panels found: " new_possible_panels.length()
        ; Progress, %progressee%, %textee%, ,Processing...

        return new_possible_panels
    }
}


;=================================END=======================================

return

F11:: pause
F12:: Reload 
