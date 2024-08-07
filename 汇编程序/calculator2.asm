MAIN:

    
    lui  s1, 0xFFFFF
TEST:
    lw   s0, 0x70(s1)           # Read switches 读进来开关的内容
    
    #sw   s0, 0x60(s1)           # Write LEDs
    #sw   s0, 0x00(s1)           # Write 7-seg LEDs
    
    # 应该先取出开关内容即s0寄存器值的[23:21]字段，用于条件判断，转移到响应的子程序执行
    srli t0,s0,21               # 将 s0 的值右移 21 位，结果存入 t0
    andi t0,t0,0x7              # 用立即数7和t0的内容做一个与运算，就是一个掩码操作，只保留t0的最低3位，其他位都一定变成0
    
    #li t1, 0                    # 0存t1，因为下面要用于比较，立即数不能直接比较，必须存入寄存器,不需要，因为应该使用x0寄存器来表示0
    beq t0,zero, FUNC0            # t0存的值是0，那么跳func0子程序，即 运算类型选择000，运算为“无”，数码管显示全0
    
    li t1, 1                    # 1存入t1寄存器，用于下面一句比较
    beq t0,t1,FUNC1             # t0存的值是1，则跳转func1子程序， 运算类型选择001，做加法A+B
    
    li t1, 2
    beq t0,t1, FUNC2            # t0值是2，那么跳func2子程序，运算类型选择为010，做减法
    
    li t1, 3
    beq t0,t1, FUNC3            # t0值是3，跳转func3子程序，运算类型选择011
    
    li t1, 4
    beq t0, t1, FUNC4           # t0值是4，跳转func4子程序，运算类型100
    
    li t1, 5
    beq t0, t1, FUNC5           # t0值是5，跳转func5子程序，运算类型选择101，生成随机数
    
    
    jal  TEST

FUNC0:
    sw    zero, 0x60(s1) 
    sw    zero, 0x00(s1)       # 把x0寄存器的值写入LED和数码管，从而实现显示全0
    jal   TEST                 # 运行完就跳转到TEST

FUNC1:
    # 首先要从s0寄存器中提取A和B，并且将他们的整数部分和小数部分分开存储。也就是存进4个寄存器
    srli   t0, s0, 8        # 将 s0 右移 8 位，提取高 8 位的 A 到 t0
    andi   t1, s0, 0xFF    # 使用掩码 0xFF 提取低 8 位的 B 到 t1
    andi   t0, t0, 0xFF    # 使用掩码 0xFF 保留 t0 的低 8 位，A 的值保存在 t0, 高位会变成全0
    # 分离 A 的整数部分和小数部分
    srli   t2, t0, 4        # t0的内容右移 4 位，得到 A 的整数部分，存入 t2
    andi   t3, t0, 0xF     # 使用掩码 0xF，得到 A 的小数部分，存入 t3
    # 分离 B 的整数部分和小数部分
    srli   t4, t1, 4        # 右移 4 位，得到 B 的整数部分，存入 t4
    andi   t5, t1, 0xF     # 使用掩码 0xF，得到 B 的小数部分，存入 t5
    
    # 此时， A整数在t2，小数在t3， B整数在t4，小数在t5
    
    add    t0, t3, t5       # 小数部分相加，结果存储到t0，之后进行进位判断
    li     t1, 10           # 保存1
    blt    t0, t1, NOCARRY     # 若t0的值小于t1，则没有进位。否则要顺序执行下面的进位操作
    # 接下来代码是有进位，小数部分大于等于10，应该把小数部分和t0的内容减去10，并且待会整数加1
    addi   t0, t0, -10      # [t0] = [t0] - 10
    addi   t2, t2, 1        # t2此时是存储了A的整数部分，那么把进位的1先加到t2里面，因为最后t2和t4都是内容相加，得到整数部分，这样后面的操作就统一了
    NOCARRY:
    add    t1, t2, t4       # t2 和t4 的值加起来，即整数部分的和，存入t1寄存器中。 到这句结束， A+B的整数部分存储在t1中，小数部分存储在t0中
    # 下面需要把t1（整数）和t0（小数）这两部分的值整合到一个字里面，载入给数码管。 
  # slli   t0, t0, 12       # t0即小数，左移12位
   # slli   t1, t1, 16       # t1即整数，左移16位
    #or     t1, t0, t1       # t0和t1或运算，就整合到了一个寄存器
    #sw     t1, 0x60(s1) 
    #sw     t1, 0x00(s1)     # 写入数码管
    #	jal   TEST                 # 运行完就跳转到TEST
    # t1的内容（整数）需要转十进制，小数不用，小数肯定是十进制
    # 代码移到FUNC2里面，直接用label无条件跳转
   DECDISPLAY:
    li t2, 0                   # 商（十位数）的初值
    li t3, 10                  # 除数是 10
    add t4, t1, zero           # 复制 t1 到 t4，t4 将用于逐步减法
    # 模拟除数为10的除法，计算商和余数  
    # 一次循环只能提纯一位的BCD码，一次循环后，个位数是真的十进制了，但是十位以上不是，十位以上还是16进制的，比如112会错误的表示成b2
    # 这样十位数也就是那个第一次出来的商，不是真正的
	loop:
	    blt t4, t3, end_loop   # 如果 t4 < 10，跳转到 end_loop
	    sub t4, t4, t3         # t4 = t4 - 10，逐步减法
	    addi t2, t2, 1         # 商 t2 加 1
	    j loop                 # 跳转回 loop 继续

	end_loop:
	    # t2 现在是十位数 (商), 在第二层中，t2就相当于上面的t1
	    # t4 现在是余数 (个位数)这个定了，后面t4不能动
	    # 如果t2是比10大的，那需要卸掉一点
	    
	    li t6, 0                   # 商（第二次，百位数）的初值
	    add t5, t2, zero           # 复制 t2 到 t5，t5 将用于逐步减法
	    
	    bge t2,t3, loop2    # 如果十位数>=10，即t2>=10,在处理一次
	    
	    slli  t1, t2, 4        # t2(十位)先左移4位，下面和t4的值或运算，拼成完整的十进制整数显示内容，存回t1
	    slli   t0, t0, 12       # t0即小数，左移12位
	    or    t1, t1, t4       # t4的值即个位，和t2左移4位后或运算，拼成十进制显示整数，存回t1
	    slli  t1, t1, 16       # t1即整数，左移16位
	    or    t1, t0, t1       # t0和t1或运算，就整合到了一个寄存器
	    sw    t1, 0x60(s1) 
            sw    t1, 0x00(s1)     # 写入数码管
            jal   TEST                 # 运行完就跳转到TEST
    	loop2:
    	    blt t5, t3, end_loop2
    	    sub t5, t5, t3
    	    addi t6, t6, 1
    	    j loop2
    	end_loop2:
    	    # 此时 t6现在是百位数（商）， t5是余数，也就是待会用到的十位数。而 第一次计算后的t4保持不变，因此t4会作为个位数
    	    slli t0,t0,12         # 小数左移12位
    	    slli t1,t6,8          # 百位左移8位
    	    slli t5,t5,4          # 十位左移4位
    	    or   t1,t1,t5        
    	    or   t1,t1,t4         # 把个位十位百位用或运算拼起来到一个寄存器里面 
    	    slli t1, t1, 16       # t1即整数，左移十六位
    	    or   t1,t0,t1         # 整数和小数拼起来到一个寄存器
    	    sw    t1, 0x60(s1) 
            sw    t1, 0x00(s1)     # 写入数码管
            jal   TEST                 # 运行完就跳转到TEST


FUNC2:    
  # 首先准备数字，直接从加法复制过来
  # 首先要从s0寄存器中提取A和B，并且将他们的整数部分和小数部分分开存储。也就是存进4个寄存器
    srli   t0, s0, 8        # 将 s0 右移 8 位，提取高 8 位的 A 到 t0
    andi   t1, s0, 0xFF    # 使用掩码 0xFF 提取低 8 位的 B 到 t1
    andi   t0, t0, 0xFF    # 使用掩码 0xFF 保留 t0 的低 8 位，A 的值保存在 t0, 高位会变成全0
    # 分离 A 的整数部分和小数部分
    srli   t2, t0, 4        # t0的内容右移 4 位，得到 A 的整数部分，存入 t2
    andi   t3, t0, 0xF     # 使用掩码 0xF，得到 A 的小数部分，存入 t3
    # 分离 B 的整数部分和小数部分
    srli   t4, t1, 4        # 右移 4 位，得到 B 的整数部分，存入 t4
    andi   t5, t1, 0xF     # 使用掩码 0xF，得到 B 的小数部分，存入 t5
    
    # 此时， A整数在t2，小数在t3， B整数在t4，小数在t5 。 下面总是计算A-B，先计算小数部分，有可能处理借位，只需要把A的整数减去1.
    
    # step1 A小数-B小数
    sub   t0, t3, t5       # A小数-B小数，结果存t0
    # step2 借位判断,如果不需要借位就跳过了，否则顺序执行借位处理
    bge   t0, zero, NOBORROW      # 若小数大于等于0，不需要借位
    # 接下来代码是需要借位的处理内容
    addi  t0, t0, 10              # 借来10，加到t0的值里面，小数部分就完成了，存在t0
    addi  t2, t2, -1              # 被减数减1
    # 算到这边的小数，应该是一定是一个 +0.3 +0.4 的一个正小数，如果后面算出来整数 -3 -7这样， 那么要发送 -3 + 0.3 = -2.7
    NOBORROW:
    # step3 整数相减
    sub   t2, t2, t4              # 整数部分相减，减完的得数存到t2
    
    # step4 求绝对值，如果整数小于0，那么加个负号
    bge   t2, zero, ABSED         # 如果t2的值大于0，说明已经是绝对值了，跳转到ABSED，否则顺序执行求绝对值
    # 如果整数值为负，且小数不为0，那么取相反数后还要减1，并且把小数再用10减一次。！！！！
    xori   t2, t2, -1              # 和-1（32个1）异或，就相当于取反，然后下面再加个1，就得到了相反数了
    addi  t2, t2, 1               # 和上面一句一起，两句使得整数变成相反数
    beq   t0, zero, HELLOFDEBUG
    li   t6,10
    sub  t0, t6, t0           # 10- 小数，作为新的小数
    addi  t2,t2, -1           # 整数翻成了绝对值之后，还要减去1
    HELLOFDEBUG:              #2024/7/8 23:31 220110430
    ABSED:
    add   t1, t2, zero           # t2的值整进t1
    # 到这个时候， t1里面存储的是整数部分，t0里面存储的的是小数部分。 到这个位置，其实和加法做出了t1存整数，t0存小数是一样的。所以后面的代码就是要送数码管，直接复制过来
    # 不应该复制过来，而是只留一份。用无条件跳转跳到转十进制送数码管的代码继续执行。
    j DECDISPLAY
    
FUNC3:
     # 首先准备数字，A和前面一样，直接复制过来
  # 首先要从s0寄存器中提取A和B，并且将他们的整数部分和小数部分分开存储。也就是存进4个寄存器
     srli   t0, s0, 8        # 将 s0 右移 8 位，提取高 8 位的 A 到 t0
     andi   t0, t0, 0xFF    # 使用掩码 0xFF 保留 t0 的低 8 位，A 的值保存在 t0, 高位会变成全0
    # 分离 A 的整数部分和小数部分
     srli   t2, t0, 4        # t0的内容右移 4 位，得到 A 的整数部分，存入 t2
     andi   t3, t0, 0xF     # 使用掩码 0xF，得到 A 的小数部分，存入 t3
     # B是8位无符号整数
     andi   t1, s0, 0xFF    # 使用掩码 0xFF 提取低 8 位的 B 到 t1，直接就完成了B的存储表示
     # B 8位无符号整数在t1  A 整数部分4位在t2 小数部分在t3
     
     # 算法：直接将A的整数和小数分别移位之后， 整数部分单位是“1”，小数部分单位是“0.1”整合到一起，要循环处理进位
     sll t2, t2, t1      # A整数部分左移B位
     sll t3, t3, t1      # B小数部分左移B位
     # 小数部分连续进位，直到小数部分小于10
     li t5, 10   # 存储数字10
     LOOP3:
     blt t3, t5, EndLOOP3  # 循环结束条件： 小数 < 10
     sub t3, t3, t5        # t3的值减去10， 即小数部分减去10
     addi t2, t2, 1        # 整数部分加1,即进位
     j LOOP3               # 跳转回去，循环
     EndLOOP3:
     # 进位结束来到这里，此时t3的值是小数，肯定是小于10的，并且肯定t3最低4位可以表示, t2是整数，并且是2进制数字
     # 小数部分存t0，整数部分存t1， 然后就可以直接跳转到子程序了
     add t0, t3, zero
     add t1, t2, zero
     j DECDISPLAY
     
FUNC4:
     # 取数和FUNC3（乘法）是一样的，直接复制过来
   # 首先准备数字，A和前面一样，直接复制过来
  # 首先要从s0寄存器中提取A和B，并且将他们的整数部分和小数部分分开存储。也就是存进4个寄存器
     srli   t0, s0, 8        # 将 s0 右移 8 位，提取高 8 位的 A 到 t0
     andi   t0, t0, 0xFF    # 使用掩码 0xFF 保留 t0 的低 8 位，A 的值保存在 t0, 高位会变成全0
    # 分离 A 的整数部分和小数部分
     srli   t2, t0, 4        # t0的内容右移 4 位，得到 A 的整数部分，存入 t2
     andi   t3, t0, 0xF     # 使用掩码 0xF，得到 A 的小数部分，存入 t3
     # B是8位无符号整数
     andi   t1, s0, 0xFF    # 使用掩码 0xFF 提取低 8 位的 B 到 t1，直接就完成了B的存储表示
     # B 8位无符号整数在t1  A 整数部分4位在t2 小数部分在t3
     
     # 用循环做，每次移位1次，然后把B减去1
     LOOP4:
     beq t1, zero, ENDLOOP4      # 如果B等于0，则结束循环
     srli t3, t3, 1              # A 的小数部分右移1位
     # 先对A的整数部分做一个判断，再右移：如果最低位是1，那么待会给小数部分加1
     andi t5, t2, 0x1            # 提取t2（A整数部分）最低位到t5
     beq t5, zero, EVEN           # 如果t5等于0， 也就是整数部分是偶数的，就无需给小数部分加5，直接跳到EVEN
     addi t3, t3, 5
     EVEN:
     srli t2, t2, 1              # A 的整数部分右移1位
     addi t1, t1, -1             # B的值减去1  
     j LOOP4
     ENDLOOP4:
     # 此时， t2存储整数部分，t3存储了小数部分
     # 直接把小数部分存t0，整数部分存t1， 然后就可以直接跳转到子程序了
     add t0, t3, zero
     add t1, t2, zero
     j DECDISPLAY
     
    
FUNC5:
     beq s0, s6, MARK
     # 若s0和s6不等,把s6改成s0，并且只有这种情况下，需要我们从s0提取出一个种子到t0.否则可以直接从MARK处往下运行，t0为上一次运行生成的随机数
     add s6, s0, zero       # [s6]=[s0]
     # 先从s0取出低16位即{A，B}
     srli t0, s0, 16      
     andi t0, t0, 0xFF       # 这两句取A到t0
     andi t1, s0, 0xFF       # 这句取B到t1
     slli t0,t0, 16
     or a3, t0, t1         # {A,B}
     #li t6,0xFFFF            # 存0xFFFF，用于下一句计算，如果用andi指令会超过范围   !!!!这两句这样写会导致了错误， 用li t6，0xFFFF没得到想要的值
     #and a3, s0, t6          # 取出s0的低16位存储在t0       # 不能用t0，临时寄存器用冲突了， 导致了错误，种子用保留寄存器来存放，下面注释的t0全都改成了s5
     slli t1, a3, 16                # t0左移16位存储到t1
     or   a3, a3, t1                # t0和t1合并通过或运算， 得到{A,B,A,B}存储到t0
     MARK:
     # 从t0中取31，21，1，0位
     srli t6, a3, 31                
     andi t6, t6, 0x1               # 这两句提取第31位到t6
     
     srli t5, a3, 21                
     andi t5, t5, 0x1               # 这两句提取第21位到t5
     
     srli t4, a3, 1                
     andi t4, t4, 0x1               # 这两句提取第1位到t4
           
     andi t3, a3, 0x1               # 这句提取第0位到t3
     
     xor t2, t3, t4     
     xor t2, t2 ,t5
     xor t2, t2 , t6               # 这三句将第31，21，1，0四位进行异或运算,得到结果t2最低位
     
     slli a3, a3, 1                # t0向左移位1次
     or a3, a3, t2                 # 左移后的t0和t2或，新值存t0， 就把异或出来的新一位加在了最低位
     # 32位随机数的值就存在t0，把它写入数码管
     
      sw    a3, 0x60(s1) 
      sw    a3, 0x00(s1)     # 写入数码管
      jal DELAY
      jal   TEST               # 运行完就跳转到TEST
     
DELAY:
    li t5, 10000000
    LOOPDELAY:
    blt t5, zero , LOOPDELAYDONE
    addi t5,t5,-1 
    j LOOPDELAY
    LOOPDELAYDONE:
    jr ra
    
