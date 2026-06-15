import '../models/story.dart';

class ApiService {
  // 获取推荐故事
  Future<List<Story>> getRecommendedStories() async {
    await Future.delayed(const Duration(seconds: 1));
    
    return [
      Story(
        id: '1',
        title: '勇敢的小兔子',
        content: '从前有一只勇敢的小兔子，它住在美丽的森林里。有一天，小兔子决定去探险...',
        summary: '一个关于勇气的温暖故事',
        imageUrl: null,
        tags: ['勇敢', '动物', '冒险'],
        createdAt: DateTime.now(),
        style: 'adventure',
      ),
      Story(
        id: '2',
        title: '星星的魔法',
        content: '在遥远的天空中，有一颗会魔法的小星星。每天晚上，它都会给小朋友们送去美梦...',
        summary: '充满魔法的睡前故事',
        imageUrl: null,
        tags: ['魔法', '奇幻', '星空'],
        createdAt: DateTime.now(),
        style: 'fantasy',
      ),
      Story(
        id: '3',
        title: '小乌龟的梦想',
        content: '小乌龟有一个梦想，它想去看大海。虽然走得慢，但它从未放弃...',
        summary: '坚持梦想的故事',
        imageUrl: null,
        tags: ['坚持', '梦想', '成长'],
        createdAt: DateTime.now(),
        style: 'educational',
      ),
    ];
  }

  // 生成故事
  Future<Map<String, dynamic>> generateStory(Map<String, dynamic> params) async {
    await Future.delayed(const Duration(seconds: 2));
    
    return {
      'success': true,
      'story': {
        'title': '${params['name']}的专属故事',
        'content': '这是一个为${params['name']}量身定制的睡前故事...',
        'summary': '专属定制故事',
      },
    };
  }
}
