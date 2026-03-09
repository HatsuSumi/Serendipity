import prisma from '../src/utils/prisma';

/**
 * 清空所有测试数据
 * 
 * 警告：这会删除数据库中的所有数据！
 * 
 * 使用方法：
 * npx ts-node scripts/clear-all-data.ts
 */
async function clearAllData() {
  try {
    console.log('⚠️  警告：即将删除数据库中的所有数据！');
    console.log('按 Ctrl+C 取消，或等待 3 秒后自动执行...');
    
    // 等待 3 秒
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    console.log('🗑️  开始清空数据...');
    
    // 按照依赖关系顺序删除（先删除子表，再删除父表）
    
    // 1. 删除社区帖子
    const deletedPosts = await prisma.communityPost.deleteMany({});
    console.log(`✅ 已删除 ${deletedPosts.count} 条社区帖子`);
    
    // 2. 删除成就解锁记录
    const deletedAchievements = await prisma.achievementUnlock.deleteMany({});
    console.log(`✅ 已删除 ${deletedAchievements.count} 条成就解锁记录`);
    
    // 3. 删除签到记录
    const deletedCheckIns = await prisma.checkIn.deleteMany({});
    console.log(`✅ 已删除 ${deletedCheckIns.count} 条签到记录`);
    
    // 4. 删除故事线
    const deletedStoryLines = await prisma.storyLine.deleteMany({});
    console.log(`✅ 已删除 ${deletedStoryLines.count} 条故事线`);
    
    // 5. 删除记录
    const deletedRecords = await prisma.record.deleteMany({});
    console.log(`✅ 已删除 ${deletedRecords.count} 条记录`);
    
    // 6. 删除用户设置
    const deletedSettings = await prisma.userSettings.deleteMany({});
    console.log(`✅ 已删除 ${deletedSettings.count} 条用户设置`);
    
    // 7. 删除会员信息
    const deletedMemberships = await prisma.membership.deleteMany({});
    console.log(`✅ 已删除 ${deletedMemberships.count} 条会员信息`);
    
    // 8. 删除刷新令牌
    const deletedTokens = await prisma.refreshToken.deleteMany({});
    console.log(`✅ 已删除 ${deletedTokens.count} 个刷新令牌`);
    
    // 9. 删除验证码
    const deletedCodes = await prisma.verificationCode.deleteMany({});
    console.log(`✅ 已删除 ${deletedCodes.count} 个验证码`);
    
    // 10. 删除用户
    const deletedUsers = await prisma.user.deleteMany({});
    console.log(`✅ 已删除 ${deletedUsers.count} 个用户`);
    
    console.log('🎉 所有数据已清空！');
  } catch (error) {
    console.error('❌ 清空失败:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

clearAllData();

