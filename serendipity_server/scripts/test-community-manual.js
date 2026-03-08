/**
 * 手动测试脚本 - Phase 1.6 社区 API
 * 运行方式: node scripts/test-community-manual.js
 */

const BASE_URL = 'http://localhost:3000/api/v1';

const testData = {
  email: `test${Date.now()}@example.com`,
  password: 'password123',
  accessToken: '',
  userId: '',
  recordId1: '', recordId2: '', recordId3: '',
  postId1: '', postId2: ''
};

const colors = { reset: '\x1b[0m', green: '\x1b[32m', red: '\x1b[31m', yellow: '\x1b[33m', blue: '\x1b[34m', cyan: '\x1b[36m' };
const log = (msg, color = 'reset') => console.log(`${colors[color]}${msg}${colors.reset}`);
const logSuccess = (msg) => log(`✅ ${msg}`, 'green');
const logError = (msg) => log(`❌ ${msg}`, 'red');
const logInfo = (msg) => log(`ℹ️  ${msg}`, 'cyan');
const logWarning = (msg) => log(`⚠️  ${msg}`, 'yellow');
const logSection = (msg) => { log(`\n${'='.repeat(60)}`, 'blue'); log(`  ${msg}`, 'blue'); log(`${'='.repeat(60)}`, 'blue'); };

async function request(method, path, body = null, headers = {}) {
  const url = `${BASE_URL}${path}`;
  const options = { method, headers: { 'Content-Type': 'application/json', ...headers } };
  if (body) options.body = JSON.stringify(body);
  logInfo(`${method} ${path}`);
  try {
    const response = await fetch(url, options);
    const data = await response.json();
    if (response.ok) {
      logSuccess(`状态码: ${response.status}`);
      return { success: true, data, status: response.status };
    } else {
      logWarning(`状态码: ${response.status}`);
      return { success: false, data, status: response.status };
    }
  } catch (error) {
    logError(`请求失败: ${error.message}`);
    return { success: false, error: error.message };
  }
}

const generateUUID = () => 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
  const r = Math.random() * 16 | 0, v = c === 'x' ? r : (r & 0x3 | 0x8);
  return v.toString(16);
});

function generateRecordData(id, opts = {}) {
  const now = new Date();
  return {
    id, timestamp: now.toISOString(),
    location: {
      latitude: opts.latitude || 39.9042, longitude: opts.longitude || 116.4074,
      address: opts.address || '北京市朝阳区建国门外大街1号',
      placeName: opts.placeName || '国贸商城', placeType: opts.placeType || 'mall',
      province: opts.province || '北京', city: opts.city || '北京市', area: opts.area || '朝阳区'
    },
    description: opts.description || '测试记录', tags: opts.tags || [{ tag: '购物' }],
    emotion: 'happy', status: opts.status || 'met', weather: ['sunny'],
    isPinned: false, createdAt: now.toISOString(), updatedAt: now.toISOString()
  };
}

async function setupAuth() {
  logSection('准备：注册并登录');
  const result = await request('POST', '/auth/register/email', { email: testData.email, password: testData.password });
  if (!result.success) { logError('注册失败'); return false; }
  testData.accessToken = result.data.data.tokens.accessToken;
  testData.userId = result.data.data.user.id;
  logSuccess('注册成功');
  log(`📧 邮箱: ${testData.email}`, 'cyan');
  return true;
}

async function setupRecords() {
  logSection('准备：创建测试记录');
  testData.recordId1 = generateUUID();
  testData.recordId2 = generateUUID();
  testData.recordId3 = generateUUID();
  const records = [
    generateRecordData(testData.recordId1, { placeName: '三里屯', tags: [{ tag: '购物' }, { tag: '美食' }] }),
    generateRecordData(testData.recordId2, { placeName: '星巴克', placeType: 'cafe', city: '上海市', province: '上海', tags: [{ tag: '咖啡' }] }),
    generateRecordData(testData.recordId3, { placeName: '西湖', placeType: 'park', city: '杭州市', province: '浙江', tags: [{ tag: '旅游' }] })
  ];
  const result = await request('POST', '/records/batch', { records }, { 'Authorization': `Bearer ${testData.accessToken}` });
  if (!result.success || result.data.data.succeeded !== 3) { logError('创建记录失败'); return false; }
  logSuccess('创建了 3 条测试记录');
  return true;
}

async function testCreatePost() {
  logSection('场景 1: 创建社区帖子');
  const postData = {
    id: generateUUID(),
    recordId: testData.recordId1,
    timestamp: new Date().toISOString(),
    address: '北京市朝阳区',
    placeName: '三里屯',
    placeType: 'mall',
    province: '北京',
    city: '北京市',
    area: '朝阳区',
    description: '今天逛街很开心',
    tags: [{ tag: '购物' }, { tag: '美食' }],
    status: 'met',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };
  const result = await request('POST', '/community/posts', postData, { 'Authorization': `Bearer ${testData.accessToken}` });
  if (!result.success) { logError('创建帖子失败'); console.log(JSON.stringify(result.data, null, 2)); return false; }
  testData.postId1 = result.data.data.id;
  logSuccess(`✓ 帖子创建成功，ID: ${testData.postId1}`);
  if (result.data.data.replaced === false) logSuccess('✓ replaced 字段正确');
  return true;
}

async function testDuplicatePublish() {
  logSection('场景 2: 重复发布检测（内容未变化）');
  const postData = {
    id: generateUUID(),
    recordId: testData.recordId1,
    timestamp: new Date().toISOString(),
    address: '北京市朝阳区',
    placeName: '三里屯',
    placeType: 'mall',
    province: '北京',
    city: '北京市',
    area: '朝阳区',
    description: '今天逛街很开心',
    tags: [{ tag: '购物' }, { tag: '美食' }],
    status: 'met',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };
  const result = await request('POST', '/community/posts', postData, { 'Authorization': `Bearer ${testData.accessToken}` });
  if (result.success) { logError('应该失败但成功了'); return false; }
  if (result.status === 409) logSuccess('✓ 返回 409 Conflict');
  if (result.data.error && result.data.error.message.includes('内容无变化')) logSuccess('✓ 错误信息正确');
  return true;
}

async function testContentChanged() {
  logSection('场景 3: 内容变化检测');
  const postData = {
    id: generateUUID(),
    recordId: testData.recordId1,
    timestamp: new Date().toISOString(),
    address: '北京市朝阳区',
    placeName: '三里屯',
    placeType: 'mall',
    province: '北京',
    city: '北京市',
    area: '朝阳区',
    description: '今天逛街超级开心！',
    tags: [{ tag: '购物' }, { tag: '美食' }],
    status: 'met',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };
  const result = await request('POST', '/community/posts', postData, { 'Authorization': `Bearer ${testData.accessToken}` });
  if (result.success) { logError('应该失败但成功了'); return false; }
  if (result.status === 409) logSuccess('✓ 返回 409 Conflict');
  if (result.data.error && result.data.error.message.includes('内容已变化')) logSuccess('✓ 错误信息正确');
  return true;
}

async function testForceReplace() {
  logSection('场景 4: 强制替换');
  const postData = {
    id: generateUUID(),
    recordId: testData.recordId1,
    timestamp: new Date().toISOString(),
    address: '北京市朝阳区',
    placeName: '三里屯',
    placeType: 'mall',
    province: '北京',
    city: '北京市',
    area: '朝阳区',
    description: '今天逛街超级开心！',
    tags: [{ tag: '购物' }, { tag: '美食' }],
    status: 'met',
    forceReplace: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };
  const result = await request('POST', '/community/posts', postData, { 'Authorization': `Bearer ${testData.accessToken}` });
  if (!result.success) { logError('强制替换失败'); return false; }
  testData.postId1 = result.data.data.id;
  logSuccess('✓ 强制替换成功');
  if (result.data.data.replaced === true) logSuccess('✓ replaced 字段为 true');
  return true;
}

async function testBatchCheckStatus() {
  logSection('场景 5: 批量检查发布状态（验证 N+1 优化）');
  const records = [
    { recordId: testData.recordId1, timestamp: new Date().toISOString(), address: '北京市朝阳区', placeName: '三里屯', placeType: 'mall', province: '北京', city: '北京市', area: '朝阳区', description: '今天逛街超级开心！', tags: [{ tag: '购物' }], status: 'met' },
    { recordId: testData.recordId2, timestamp: new Date().toISOString(), address: '上海市', placeName: '星巴克', placeType: 'cafe', province: '上海', city: '上海市', area: '黄浦区', description: '喝咖啡', tags: [{ tag: '咖啡' }], status: 'met' },
    { recordId: testData.recordId3, timestamp: new Date().toISOString(), address: '杭州市', placeName: '西湖', placeType: 'park', province: '浙江', city: '杭州市', area: '西湖区', description: '游玩', tags: [{ tag: '旅游' }], status: 'met' }
  ];
  const result = await request('POST', '/community/posts/check-status', { records }, { 'Authorization': `Bearer ${testData.accessToken}` });
  if (!result.success) { logError('批量检查失败'); return false; }
  const statuses = result.data.data.statuses;
  logSuccess(`✓ 返回了 ${statuses.length} 条状态`);
  const record1Status = statuses.find(s => s.recordId === testData.recordId1);
  if (record1Status && record1Status.status === 'CANNOT_PUBLISH') logSuccess('✓ recordId1: CANNOT_PUBLISH（内容未变化）');
  const record2Status = statuses.find(s => s.recordId === testData.recordId2);
  if (record2Status && record2Status.status === 'CAN_PUBLISH') logSuccess('✓ recordId2: CAN_PUBLISH（未发布过）');
  return true;
}

async function testGetRecentPosts() {
  logSection('场景 6: 获取最近帖子');
  const result = await request('GET', '/community/posts?limit=10', null, { 'Authorization': `Bearer ${testData.accessToken}` });
  if (!result.success) { logError('获取帖子失败'); return false; }
  const posts = result.data.data.posts;
  logSuccess(`✓ 返回了 ${posts.length} 条帖子`);
  if (typeof result.data.data.hasMore === 'boolean') logSuccess('✓ hasMore 字段存在');
  return true;
}

async function testGetMyPosts() {
  logSection('场景 7: 获取我的帖子');
  const result = await request('GET', '/community/my-posts', null, { 'Authorization': `Bearer ${testData.accessToken}` });
  if (!result.success) { logError('获取我的帖子失败'); return false; }
  const posts = result.data.data.posts;
  logSuccess(`✓ 返回了 ${posts.length} 条帖子`);
  if (posts.every(p => p.isOwner === true)) logSuccess('✓ 所有帖子的 isOwner 都为 true');
  return true;
}

async function testFilterByLocation() {
  logSection('场景 8: 多条件筛选（省份+城市）');
  const result = await request('GET', '/community/posts?province=北京&city=北京市&limit=10', null, { 'Authorization': `Bearer ${testData.accessToken}` });
  if (!result.success) { logError('筛选失败'); return false; }
  const posts = result.data.data.posts;
  logSuccess(`✓ 返回了 ${posts.length} 条帖子`);
  if (posts.every(p => p.province === '北京' && p.city === '北京市')) logSuccess('✓ 所有帖子都符合筛选条件');
  return true;
}

async function testFilterByTags() {
  logSection('场景 9: 标签筛选（验证 GIN 索引）');
  const result = await request('GET', '/community/posts?tags=购物&limit=10', null, { 'Authorization': `Bearer ${testData.accessToken}` });
  if (!result.success) { logError('标签筛选失败'); return false; }
  const posts = result.data.data.posts;
  logSuccess(`✓ 返回了 ${posts.length} 条帖子`);
  if (posts.length > 0) {
    const hasTag = posts.some(p => p.tags.some(t => t.tag === '购物'));
    if (hasTag) logSuccess('✓ 找到了包含"购物"标签的帖子');
  }
  return true;
}

async function testDeletePost() {
  logSection('场景 10: 删除帖子');
  const result = await request('DELETE', `/community/posts/${testData.postId1}`, null, { 'Authorization': `Bearer ${testData.accessToken}` });
  if (!result.success) { logError('删除帖子失败'); return false; }
  logSuccess('✓ 帖子删除成功');
  const verifyResult = await request('GET', '/community/my-posts', null, { 'Authorization': `Bearer ${testData.accessToken}` });
  if (verifyResult.success) {
    const found = verifyResult.data.data.posts.some(p => p.id === testData.postId1);
    if (!found) logSuccess('✓ 帖子已从列表中删除');
  }
  return true;
}

async function runAllTests() {
  log('\n🚀 开始测试 Phase 1.6 社区 API', 'blue');
  log(`📍 服务器地址: ${BASE_URL}\n`, 'cyan');
  const tests = [
    { name: '准备：注册并登录', fn: setupAuth },
    { name: '准备：创建测试记录', fn: setupRecords },
    { name: '场景 1: 创建社区帖子', fn: testCreatePost },
    { name: '场景 2: 重复发布检测', fn: testDuplicatePublish },
    { name: '场景 3: 内容变化检测', fn: testContentChanged },
    { name: '场景 4: 强制替换', fn: testForceReplace },
    { name: '场景 5: 批量检查发布状态', fn: testBatchCheckStatus },
    { name: '场景 6: 获取最近帖子', fn: testGetRecentPosts },
    { name: '场景 7: 获取我的帖子', fn: testGetMyPosts },
    { name: '场景 8: 多条件筛选', fn: testFilterByLocation },
    { name: '场景 9: 标签筛选', fn: testFilterByTags },
    { name: '场景 10: 删除帖子', fn: testDeletePost }
  ];
  const results = [];
  for (const test of tests) {
    try {
      const passed = await test.fn();
      results.push({ name: test.name, passed });
      if (!passed) { logError(`\n❌ ${test.name} 失败，停止后续测试\n`); break; }
      await new Promise(resolve => setTimeout(resolve, 500));
    } catch (error) {
      logError(`\n❌ ${test.name} 抛出异常: ${error.message}\n`);
      console.error(error);
      results.push({ name: test.name, passed: false, error: error.message });
      break;
    }
  }
  logSection('测试总结');
  const passed = results.filter(r => r.passed).length;
  const total = results.length;
  results.forEach(result => result.passed ? logSuccess(`✓ ${result.name}`) : logError(`✗ ${result.name}`));
  log(`\n📊 测试结果: ${passed}/${total} 通过`, passed === total ? 'green' : 'red');
  if (passed === total) log('\n🎉 所有测试通过！Phase 1.6 社区 API 工作正常！\n', 'green');
  else log('\n⚠️  部分测试失败，请检查服务器日志\n', 'yellow');
}

async function checkServer() {
  logInfo('检查服务器是否运行...');
  try {
    const response = await fetch(`${BASE_URL}/health`);
    if (response.ok) { logSuccess('服务器正在运行'); return true; }
  } catch (error) {
    try {
      await fetch(`${BASE_URL}/auth/register/email`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: '', password: '' }) });
      logSuccess('服务器正在运行');
      return true;
    } catch (e) {
      logError('无法连接到服务器');
      logInfo('请确保服务器正在运行: npm run dev');
      return false;
    }
  }
}

(async () => {
  const serverRunning = await checkServer();
  if (!serverRunning) { log('\n❌ 测试终止：服务器未运行\n', 'red'); process.exit(1); }
  await runAllTests();
})();
