/**
 * 修复数据库中的 placeType 值
 * 将 shopping_mall 改为 mall
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function fixPlaceType() {
  console.log('🔍 查找包含 shopping_mall 的记录...');
  
  // 修复 community_posts 表
  const posts = await prisma.communityPost.findMany({
    where: {
      placeType: 'shopping_mall'
    }
  });
  
  console.log(`📊 找到 ${posts.length} 条社区帖子需要修复`);
  
  if (posts.length > 0) {
    const result = await prisma.communityPost.updateMany({
      where: {
        placeType: 'shopping_mall'
      },
      data: {
        placeType: 'mall'
      }
    });
    
    console.log(`✅ 已修复 ${result.count} 条社区帖子`);
  }
  
  // 修复 records 表中的 location.placeType
  const records = await prisma.record.findMany();
  let fixedRecords = 0;
  
  for (const record of records) {
    const location = record.location;
    if (location && location.placeType === 'shopping_mall') {
      location.placeType = 'mall';
      await prisma.record.update({
        where: { id: record.id },
        data: { location }
      });
      fixedRecords++;
    }
  }
  
  console.log(`✅ 已修复 ${fixedRecords} 条记录`);
  console.log('🎉 修复完成！');
}

fixPlaceType()
  .catch(console.error)
  .finally(() => prisma.$disconnect());

