/**
 * 删除所有社区帖子（通过 API）
 */

const BASE_URL = 'http://localhost:3000/api/v1';

async function deleteAllPosts() {
  console.log('🔍 获取所有帖子...');
  
  // 1. 先注册一个临时账号
  const email = `temp${Date.now()}@example.com`;
  const password = 'password123';
  
  const registerRes = await fetch(`${BASE_URL}/auth/register/email`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });
  
  if (!registerRes.ok) {
    console.error('❌ 注册失败');
    return;
  }
  
  const registerData = await registerRes.json();
  const token = registerData.data.tokens.accessToken;
  
  console.log('✅ 已登录');
  
  // 2. 获取我的帖子
  const myPostsRes = await fetch(`${BASE_URL}/community/my-posts`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  
  if (!myPostsRes.ok) {
    console.error('❌ 获取帖子失败');
    return;
  }
  
  const myPostsData = await myPostsRes.json();
  const posts = myPostsData.data.posts;
  
  console.log(`📊 找到 ${posts.length} 条我的帖子`);
  
  // 3. 删除所有帖子
  for (const post of posts) {
    const deleteRes = await fetch(`${BASE_URL}/community/posts/${post.id}`, {
      method: 'DELETE',
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    if (deleteRes.ok) {
      console.log(`✅ 已删除帖子: ${post.id}`);
    } else {
      console.error(`❌ 删除失败: ${post.id}`);
    }
  }
  
  console.log('🎉 删除完成！');
}

deleteAllPosts().catch(console.error);

