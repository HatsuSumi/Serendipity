import prisma from '../src/utils/prisma';

/**
 * 删除指定邮箱的用户及其所有数据
 * 
 * 使用方法：
 * npx ts-node scripts/delete-user.ts a19171548397a@163.com
 */
async function deleteUser(email: string) {
  try {
    console.log(`🗑️  开始删除用户: ${email}`);
    
    // 查找用户
    const user = await prisma.user.findUnique({
      where: { email },
    });
    
    if (!user) {
      console.log('❌ 用户不存在');
      return;
    }
    
    console.log(`✅ 找到用户: ${user.id}`);
    
    // 删除用户的所有数据（Prisma 会自动级联删除）
    // 包括：records, storyLines, checkIns, achievements, communityPosts 等
    await prisma.user.delete({
      where: { id: user.id },
    });
    
    console.log('🎉 用户及其所有数据已删除！');
  } catch (error) {
    console.error('❌ 删除失败:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

// 从命令行参数获取邮箱
const email = process.argv[2];

if (!email) {
  console.error('❌ 请提供邮箱地址');
  console.log('使用方法: npx ts-node scripts/delete-user.ts <email>');
  process.exit(1);
}

deleteUser(email);

