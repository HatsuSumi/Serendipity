/**
 * 清空社区帖子（测试数据）
 */

const { PrismaClient } = require('@prisma/client');

async function clearCommunityPosts() {
  const prisma = new PrismaClient();
  
  try {
    console.log('🗑️  清空社区帖子...');
    
    const result = await prisma.communityPost.deleteMany({});
    
    console.log(`✅ 已删除 ${result.count} 条社区帖子`);
    console.log('🎉 清理完成！现在可以重新测试了');
  } catch (error) {
    console.error('❌ 清理失败:', error);
  } finally {
    await prisma.$disconnect();
  }
}

clearCommunityPosts();

