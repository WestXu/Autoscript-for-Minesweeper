F10::

;===============================常量========================================

;延时常量
delayer := 50

;鼠标速度
SetDefaultMouseSpeed, 0
SetMouseDelay, 2 ; 设为小于2时会出现卡死bug，尚未解决

;激活扫雷窗口
WinWait, 扫雷
WinActivate, 扫雷

blocksize := 16
left_x := 16
top_y := 100
right_x := left_x + blocksize * 30
bottom_y := top_y + blocksize * 16
halfsize := blocksize // 2

;颜色常量
color_to_num := {0xC0C0C0: 0, 0x0000FF: 1, 0x008000: 2, 0xFF0000: 3, 0x000080: 4, 0x800000: 5, 0x008080: 6, 0x000000: 7, 0x808080: 8}

;用于循环的数组
thirty := [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30]
sixteen := [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]

;第一个方块的坐标
firstblock_x := left_x + halfsize
firstblock_y := top_y + halfsize


;=================================END=======================================


初始化面板: 
blocktable := {}
for r in sixteen {
    for c in thirty {    
        blocktable[r, c] := new Block(r, c)
    }
}


第一步: ;点开中间的一个
blocktable[16, 30].Open()


第二步: ;遍历单数字推断，直到无法插旗无法点开 
loop {
    dealed := 0
    for r in sixteen {
        for c in thirty {
            check_block := blocktable[r, c]
            if (check_block.num > 0) {
                if (!check_block.finalled) { 

                    ; 数数数字周围旗子的数量和没开的block的数量
                    flags := 0 
                    close_block_num := 0
                    close_blocks := []
                    for i, block in SurroundingBlocks(check_block) {
                        if (!block.openned) {
                            close_block_num++
                            close_blocks.Insert(block)
                            if (block.flagged) {
                                flags++
                            }
                        }
                    }
                    ; msgbox, % "旗子数：" flags "`r关闭的格子数：" close_block_num "`r数字：" check_block.num


                    ;如果旗子数量等于数字，打开数字周围
                    if (check_block.num == flags && flags < close_block_num) {
                        for i, block in close_blocks {
                            block.Open()
                            dealed++
                        }
                        check_block.finalled := True
                    }

                    ;如果没开的的数量等于数字，就把周围插上旗子
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


第三步: ;找到边缘所有block
edge_blocks := []
for r in sixteen {
    for c in thirty {  
        if (blocktable[r, c].num > 0 && !blocktable[r, c].finalled) {
            for i, block in SurroundingBlocks(blocktable[r, c]) {
                if (!block.openned && !block.flagged) {
                    if (!IsIn(block, edge_blocks)) {
                        edge_blocks.Insert(block)
                    }
                }
            }                                
        }
    }
}

; 没有了就结束
if (edge_blocks == []) {
    Reload
}


第四步: ;概率最小的点开
possible_panels := PossiblePanels(edge_blocks)
ToolTip

;用于累加每个block出现雷的次数
counts := [] 
for step in possible_panels[1] {
    counts[step] := 0
}

for i, panel in possible_panels { ;对所有block出现雷的次数累加
    for step, mark in panel {
        counts[step] += mark
    }
}

did_flag := False
for step, marks in counts { ;如果有block在所有panel中都有雷，插旗子
    if (marks == possible_panels.Length()) {
        step.Flag()
        did_flag := True
    }
}

;如果有block在所有panel中都没有出现过雷，点开
did_open := False
for step, marks in counts { 
    if (marks == 0) {
        step.Open()
        did_open := True
    }
}

;如果没有一个绝对安全的block可以点开，那就点开概率最小的
if (!did_open && !did_flag) { 
    ; msgbox, % "边缘长度：" edge_blocks.length() "`r插旗子：" did_flag "`r打开过：" did_open "`r开始蒙"
    min_marks := possible_panels.Length() + 1 ;初始值设置为比最大可能值大1
    for step, marks in counts {
        if (marks <= min_marks) {
            min_marks := marks 
            min_marks_step := step ;找出雷出现次数最少的一个block
        }    
    } 
    min_marks_step.Open()

    ; 检查有没有猜错，猜错了就结束
    PixelGetColor, Getcolor, min_marks_step.x - 6, min_marks_step.y - 6, RGB
    if (Getcolor == 0xFF0000) { 
        MsgBox, 5, , Bad luck. 
        IfMsgBox, Retry 
        {
            Click 257, 75 ; 点笑脸重新开始
            Goto, 初始化面板
        }
        Reload
    }
}

Goto, 第二步

;===============================子过程======================================

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
        this.flagged := False
        this.openned := False
        this.num := ""
        this.finalled := False
    }

    Open(really_oppend := False) {
        if (!this.openned && !this.flagged) {
            if (!really_oppend) {
                Mousemove, this.x, this.y
                Click
            }
            this.openned := True
            if (this.num == "") { ;没有检查过数字的话就检查一下
                PixelGetColor, Getcolor, this.x, this.y, RGB
                this.num := ColorToNum(Getcolor)
                if (this.num == 0) { ;如果点开发现是空的，就会打开四周
                    for i, block in SurroundingBlocks(this) {
                        block.Open(True)
                    }
                }
            }
        }   
    }

    Flag() {
        if (!this.flagged) {
            Mousemove, this.x, this.y
            Click Right
            this.flagged := True
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

xOfc(c) { ; 根据列找x坐标
    global
    return (c - 1) * blocksize + firstblock_x
}

yOfr(r) { ; 根据行找y坐标
    global
    return (r - 1) * blocksize + firstblock_y
}

SurroundingBlocks(block) {
    global blocktable
    surrounding_blocks := []
    for i, small_r in [-1, 0, 1] {
        for i, small_c in [-1, 0, 1] {
            if (!(small_r == 0 && small_c == 0)) {
                real_r := block.r + small_r
                real_c := block.c + small_c
                if (real_r > 0 && real_r <= 16 && real_c >0 && real_c <= 30) {
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
            reject0 := False ; 初始化两个拒绝状态
            reject1 := False

            now_step := blocks[LengthOfList(panel)+1]
            for i, num_block in SurroundingBlocks(now_step) { ;走到当前这一块，它的周围8个遍历
                if (num_block.num > 0) { ;有数字的block

                    ; 计算未点开的block的数量、旗子的数量、标记过的1或0的数量
                    close_block_num := 0
                    flags := 0
                    marked_zeros := 0 
                    marked_ones := 0
                    for i, block in SurroundingBlocks(num_block) { ;数字周围的block
                        if (!block.openned) {
                            close_block_num++
                        }
                        if (block.flagged)
                            flags++
                        if (panel.HasKey(block)) { ; 如果数字周围的block在之前走过的路径中
                            if (panel[block] == 1) {
                                marked_ones++
                            }
                            if (panel[block] == 0) {
                                marked_zeros++
                            }
                        }
                    }
                    if (num_block.num == close_block_num - marked_zeros) { ;满足条件一，不可以无雷
                        reject0 := True                    
                    }
                    if (num_block.num == marked_ones + flags) { ;满足条件二，不可以有雷
                        reject1 := True 
                    }
                }
            }

            if (!reject0) {
                panel0 := panel.Clone()
                panel0.Insert(now_step, 0)
                new_possible_panels.Insert(panel0)
            }
            if (!reject1) {
                panel1 := panel.Clone()
                panel1.Insert(now_step, 1)
                new_possible_panels.Insert(panel1) 
            }
        }

        ;PrintListOfList(new_possible_panels)
        ToolTip, % "Step: " LengthOfList(new_possible_panels[1]) " / " edge_blocks.Length() "`rPossible panels found: " new_possible_panels.Length()

        return new_possible_panels
    }
}


;=================================END=======================================

Return

F11:: Pause
F12:: Reload 
