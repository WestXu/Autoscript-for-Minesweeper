import pyautogui as ahk


#======================================Constants==========================


ahk.PAUSE = 0.005

left_x, top_y, width, height = ahk.locateOnScreen('initial_screenshot.png')

blocksize = 16
halfsize = blocksize // 2

# 颜色常量
color_to_num = {(192, 192, 192): 0,
                (0, 0, 255): 1,
                (0, 128, 0): 2,
                (255, 0, 0): 3,
                (0, 0, 128): 4,
                (128, 0, 0): 5,
                (0, 128, 128): 6,
                (0, 0, 0): 7,
                (128, 128, 128): 8}


#======================================Functions==========================


def SurroundingBlocks(block):
    surrounding_blocks = []
    for small_r in [-1, 0, 1]:
        for small_c in [-1, 0, 1]:
            if not (small_r == 0 and small_c == 0):
                real_r = block.r + small_r
                real_c = block.c + small_c
                if real_r >= 0 and real_r < 16 and real_c >= 0 and real_c < 30:
                    surrounding_blocks.append(blocktable[real_r][real_c])
    return surrounding_blocks


def PossiblePanels(blocks):
    if len(blocks) == 0:
        return [{}]
    else:

        new_possible_panels = []
        less_blocks = blocks[:]
        less_blocks.pop()

        for panel in PossiblePanels(less_blocks):
            reject0 = False
            reject1 = False

            now_step = blocks[len(panel)]
            for num_block in SurroundingBlocks(now_step):  # 走到当前这一块，它的周围8个遍历
                if (not num_block.num is None) and num_block.num > 0:  # 有数字的block

                    # 计算未点开的block的数量、旗子的数量、标记过的1或0的数量
                    close_block_num = 0
                    flags = 0
                    marked_zeros = 0
                    marked_ones = 0
                    for block2 in SurroundingBlocks(num_block):
                        if not block2.openned:
                            close_block_num += 1
                        if block2.flagged:
                            flags += 1
                        if block2 in panel:
                            if (panel[block2] == 1):
                                marked_ones += 1
                            if (panel[block2] == 0):
                                marked_zeros += 1
                    if num_block.num == close_block_num - marked_zeros:
                        reject0 = True
                    if num_block.num == marked_ones + flags:
                        reject1 = True

            if not reject0:
                panel0 = panel.copy()
                panel0[now_step] = 0
                new_possible_panels.append(panel0)
            if not reject1:
                panel1 = panel.copy()
                panel1[now_step] = 1
                new_possible_panels.append(panel1)

        print('Step: ', len(new_possible_panels[0]), ' / ', len(edge_blocks),
              '\nPossible panels found: ', len(new_possible_panels))

        return new_possible_panels


class Block(object):

    def __init__(self, r, c):
        self.r = r
        self.c = c
        self.x = left_x + halfsize + c * blocksize
        self.y = top_y + halfsize + r * blocksize
        self.flagged = False
        self.openned = False
        self.num = None
        self.finalled = False

    def Open(self, really_oppend=False):
        if (not self.openned) and (not self.flagged):
            if not really_oppend:
                ahk.click(self.x, self.y)
            self.openned = True
            if self.num is None:
                self.num = color_to_num[ahk.pixel(self.x, self.y)]
                if self.num == 0:
                    for block in SurroundingBlocks(self):
                        block.Open(really_oppend=True)

    def Flag(self):
        if not self.flagged:
            ahk.click(self.x, self.y, button='right')
            self.flagged = True

    def MouseOn(self):
        ahk.moveTo(self.x, self.y)


#======================================START==============================



# 初始化面板
blocktable = []
for r in range(16):
    blockrow = []
    for c in range(30):
        blockrow.append(Block(r, c))
    blocktable.append(blockrow)


# 第一步：点开中间的一个
ahk.click(left_x - 5, top_y - 5)
blocktable[15][29].Open()


# 第二步：遍历单数字推断，直到无法插旗无法点开
while True:
    dealed = 1
    while dealed > 0:
        dealed = 0
        for r in range(16):
            for c in range(30):
                check_block = blocktable[r][c]
                if (not check_block.num is None) and check_block.num > 0:
                    if not check_block.finalled:

                        flags = 0
                        close_block_num = 0
                        close_blocks = []
                        for block in SurroundingBlocks(check_block):
                            if not block.openned:
                                close_block_num += 1
                                close_blocks.append(block)
                                if block.flagged:
                                    flags += 1

                        if check_block.num == flags and flags < close_block_num:
                            for block in close_blocks:
                                block.Open()
                                dealed += 1
                            check_block.finalled = True

                        if check_block.num == close_block_num and flags < close_block_num:
                            for block in close_blocks:
                                block.Flag()
                                dealed += 1
                            check_block.finalled = True

    # 第三步：找到边缘所有block
    edge_blocks = []
    for r in range(16):
        for c in range(30):
            if (not blocktable[r][c].num is None) and blocktable[r][c].num > 0 and not blocktable[r][c].finalled:
                for block in SurroundingBlocks(blocktable[r][c]):
                    if (not block.openned) and (not block.flagged):
                        if not block in edge_blocks:
                            edge_blocks.append(block)

    # 没有了就结束
    if edge_blocks == []:
        exit()

    # 第四步：概率最小的点开
    possible_panels = PossiblePanels(edge_blocks)

    # 用于累加每个block出现雷的次数
    counts = {}
    for step in possible_panels[0]:
        counts[step] = 0

    for panel in possible_panels:
        for step in panel:
            counts[step] += panel[step]

    did_flag = False
    for step in counts:
        if counts[step] == len(possible_panels):
            step.Flag()
            did_flag = True

    did_open = False
    for step in counts:
        if counts[step] == 0:
            step.Open()
            did_open = True

    if (not did_open) and (not did_flag):
        min_marks = len(possible_panels) + 1
        for step in counts:
            if counts[step] <= min_marks:
                min_marks = counts[step]
                min_marks_step = step
        min_marks_step.Open()

        # 检查有没有猜错，猜错了就结束
        if ahk.pixel(min_marks_step.x - 6, min_marks_step.y - 6) == (255, 0, 0):
            print('Bad luck. ')
            exit()
