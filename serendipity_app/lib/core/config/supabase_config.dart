/// Supabase 配置
/// 
/// 包含 Supabase 项目的连接信息。
/// 从 Supabase Dashboard → Project Settings → API 获取。
class SupabaseConfig {
  /// Project URL
  /// 
  /// 从 Supabase Dashboard 获取
  static const String url = 'https://inpzkfrjqwyumttnsigv.supabase.co';
  
  /// Anon Public Key
  /// 
  /// 用于客户端访问，可以安全地暴露在前端代码中。
  /// 配合 Row Level Security (RLS) 使用，确保数据安全。
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlucHprZnJqcXd5dW10dG5zaWd2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIwMDc0NzgsImV4cCI6MjA4NzU4MzQ3OH0.qsO8k-8lgcblYBtGqSDa_t5S5FijavB4n-Q4QPxOR2w';
}

