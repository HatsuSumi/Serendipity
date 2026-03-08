-- 修复 community_posts 表中的 shopping_mall
UPDATE community_posts 
SET place_type = 'mall' 
WHERE place_type = 'shopping_mall';

-- 查看修复结果
SELECT COUNT(*) as fixed_count 
FROM community_posts 
WHERE place_type = 'mall';

