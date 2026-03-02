import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import bcrypt from 'bcrypt';
import dotenv from 'dotenv';

// 加载环境变量
dotenv.config();

// 初始化数据库连接
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function setRecoveryKey() {
  try {
    const email = 'a19171548397a@163.com';
    const recoveryKey = '1111-1111-1111-1111-1111-1111-1111-1111';
    
    // 查找用户
    const user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      console.log('❌ 用户不存在');
      return;
    }

    // 哈希恢复密钥
    const recoveryKeyHash = await bcrypt.hash(recoveryKey, 10);

    // 更新恢复密钥
    await prisma.user.update({
      where: { id: user.id },
      data: { recoveryKey: recoveryKeyHash },
    });

    console.log('='.repeat(80));
    console.log('✅ 恢复密钥设置成功！');
    console.log('邮箱:', email);
    console.log('恢复密钥:', recoveryKey);
    console.log('='.repeat(80));
    console.log('现在你可以使用这个恢复密钥重置密码了');
  } catch (error) {
    console.error('❌ 设置失败:', error);
  } finally {
    await prisma.$disconnect();
    await pool.end();
  }
}

setRecoveryKey();

