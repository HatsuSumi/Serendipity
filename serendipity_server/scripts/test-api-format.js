/**
 * 测试 API 返回的数据格式
 */

const BASE_URL = 'http://localhost:3000/api/v1';

async function testAllAPIs() {
  console.log('🧪 测试所有 API 返回格式\n');
  
  // 1. 注册并登录
  const email = `test${Date.now()}@example.com`;
  const password = 'password123';
  
  const registerRes = await fetch(`${BASE_URL}/auth/register/email`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });
  
  const registerData = await registerRes.json();
  const token = registerData.data.tokens.accessToken;
  
  console.log('✅ 已登录\n');
  
  // 2. 测试 Records API
  console.log('📦 Records API:');
  const recordsRes = await fetch(`${BASE_URL}/records`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const recordsData = await recordsRes.json();
  console.log(`  - data.records: ${Array.isArray(recordsData.data?.records) ? '✅ 数组' : '❌ ' + typeof recordsData.data?.records}`);
  
  // 3. 测试 StoryLines API
  console.log('📖 StoryLines API:');
  const storylinesRes = await fetch(`${BASE_URL}/storylines`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const storylinesData = await storylinesRes.json();
  console.log(`  - data.storyLines: ${Array.isArray(storylinesData.data?.storyLines) ? '✅ 数组' : '❌ ' + typeof storylinesData.data?.storyLines}`);
  console.log(`  - data.storylines (旧字段): ${storylinesData.data?.storylines !== undefined ? '❌ 仍存在' : '✅ 已移除'}`);
  
  // 4. 测试 CheckIns API
  console.log('📅 CheckIns API:');
  const checkInsRes = await fetch(`${BASE_URL}/check-ins`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const checkInsData = await checkInsRes.json();
  console.log(`  - data.checkIns: ${Array.isArray(checkInsData.data?.checkIns) ? '✅ 数组' : '❌ ' + typeof checkInsData.data?.checkIns}`);
  
  console.log('\n🎉 测试完成！');
}

testAllAPIs().catch(console.error);

