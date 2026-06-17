import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// API 服务类 - 纯本地实现，无需后端
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal();

  // 故事标题池 - 按风格分类
  static const Map<String, List<String>> _titlePools = {
    'fairy_tale': ['魔法森林奇遇', '月光公主', '会飞的小猪', '彩虹尽头的宝藏', '小精灵的秘密', '花朵王国', '星星的眼泪', '魔法森林历险记', '云朵棉花糖', '小小魔法师'],
    'adventure': ['勇敢的小探险家', '神秘岛屿寻宝记', '雪山大冒险', '海底两万里', '恐龙岛探险', '迷失的丛林', '沙漠寻宝记', '海盗船的秘密', '穿越时空之旅', '神秘地图的秘密'],
    'warm': ['爸爸的晚安拥抱', '妈妈的味道', '温暖的小床', '奶奶的手织毛衣', '爷爷的故事', '家里的灯光', '快乐的星期天', '一家人的旅行', '温暖的午后', '冬天里的暖炉'],
    'educational': ['学会分享的小熊', '勇敢承认错误', '自己的事情自己做', '对人有礼貌', '珍惜每一粒粮食', '学会倾听的小花', '坚持就是胜利', '善良的小狗', '节约用水的小鸭子', '爱护小动物'],
  };

  static const Map<String, List<String>> _scenePools = {
    'fairy_tale': ['在一片神奇的森林里', '在高高的云端上', '在彩虹的尽头', '在一座古老的城堡里', '在花朵王国的中心', '在一片会唱歌的森林中'],
    'adventure': ['在一座无人岛上', '在高高的雪山顶上', '在深邃的海底', '在茂密的丛林中', '在广阔的沙漠里', '在一艘航行的船上'],
    'warm': ['在温暖的小屋里', '在温馨的餐桌上', '在柔软的床上', '在奶奶的怀里', '在洒满阳光的阳台上', '在暖暖的火炉边'],
    'educational': ['在幼儿园里', '在家里的客厅', '在公园的草地上', '在学校的操场上', '在图书馆里', '在餐桌旁边'],
  };

  static const Map<String, List<String>> _charPools = {
    'fairy_tale': ['一个穿着红裙子的小女孩', '一只会说话的小兔子', '一位善良的小精灵', '一个戴着魔法帽的小仙子', '一只会飞的独角兽'],
    'adventure': ['一个穿着探险服的小男孩', '一位勇敢的船长', '一只聪明的小猴子', '一个戴着墨镜的探险家', '一只可爱的小狗狗'],
    'warm': ['一个抱着娃娃的小女孩', '一个戴着眼镜的爸爸', '一位温柔的妈妈', '一个慈祥的奶奶', '一个爱笑的爷爷'],
    'educational': ['一只爱学习的小熊', '一个有礼貌的小女孩', '一个调皮但善良的小男孩', '一只乐于助人的小狗', '一个懂事的好孩子'],
  };

  String _pickRandom(List<String> list) {
    return list[Random().nextInt(list.length)];
  }

  /// 生成故事 - 根据风格和孩子信息生成不同故事
  Future<Map<String, dynamic>> generateStory({
    required String childName,
    required int childAge,
    required List<String> interests,
    String style = 'fairy_tale',
    List<String>? directions,
  }) async {
    // 检查会员状态
    final prefs = await SharedPreferences.getInstance();
    final isVip = prefs.getBool('vip_is_vip') ?? false;
    final vipExpire = prefs.getString('vip_expire');

    bool vipValid = isVip;
    if (isVip && vipExpire != null) {
      final expireTime = DateTime.tryParse(vipExpire);
      if (expireTime != null && expireTime.isBefore(DateTime.now())) {
        vipValid = false;
      }
    }

    // 非会员检查免费次数
    if (!vipValid) {
      final freeCount = prefs.getInt('free_generate_count') ?? 0;
      // 每次生成 +1，超过 3 次提示会员
      if (freeCount >= 3) {
        return {
          'code': 403,
          'message': '免费次数已用完，开通会员可无限生成故事',
          'data': null,
        };
      }
      await prefs.setInt('free_generate_count', freeCount + 1);
    }

    // 根据风格选择素材池
    final titles = _titlePools[style] ?? _titlePools['fairy_tale']!;
    final scenes = _scenePools[style] ?? _scenePools['fairy_tale']!;
    final characters = _charPools[style] ?? _charPools['fairy_tale']!;

    // 组合一个唯一的故事
    final title = _pickRandom(titles);
    final scene = _pickRandom(scenes);
    final character = _pickRandom(characters);
    final interestStr = interests.isNotEmpty ? interests.join('、') : '玩耍';

    // 构建故事内容（根据风格使用不同语气）
    String storyContent;
    if (style == 'fairy_tale') {
      storyContent = _buildFairyTaleStory(title, scene, character, childName, childAge, interestStr);
    } else if (style == 'adventure') {
      storyContent = _buildAdventureStory(title, scene, character, childName, childAge, interestStr);
    } else if (style == 'warm') {
      storyContent = _buildWarmStory(title, scene, character, childName, childAge, interestStr);
    } else {
      storyContent = _buildEducationalStory(title, scene, character, childName, childAge, interestStr);
    }

    return {
      'code': 200,
      'message': 'success',
      'data': {
        'id': Random().nextInt(100000).toString(),
        'title': title,
        'content': storyContent,
        'created_at': DateTime.now().toIso8601String(),
        'style': style,
      }
    };
  }

  String _buildFairyTaleStory(String title, String scene, String character, String name, int age, String interest) {
    return '''$scene，住着$character。
$character的名字叫$name，今年$age岁了，最喜欢$interest了。
有一天，$name在花园里玩的时候，发现了一朵闪闪发光的小花。
小花轻轻摇摆着，突然开口说话了：「$name，你愿意跟我去一个神奇的地方吗？」
$name开心地点了点头。小花带着$name飞过了一座又一座的小山丘，穿过了一片又一片的云朵。
最后，他们来到了一个美丽的彩虹桥上。彩虹桥上有好多好多的小星星，正在一闪一闪地唱着歌。
小星星们看到$name，都开心地飞过来，围着$name跳舞。
$name和小星星们一起唱歌，一起跳舞，玩得真开心呀。
太阳快要下山的时候，小花说：「$name，我们该回家啦。」
$name挥挥手，和小星星们说再见。
回到家里，$name躺在自己的小床上，想着今天的奇遇。
窗外的月亮婆婆温柔地看着$name，好像在说：晚安，小宝贝。
$name闭上眼睛，进入了甜甜的梦乡。
晚安，$name，做个好梦吧。✨🌙''';
  }

  String _buildAdventureStory(String title, String scene, String character, String name, int age, String interest) {
    return '''$scene，住着一位勇敢的小冒险家。
小冒险家的名字叫$name，今年$age岁了，最喜欢$interest了。
有一天，$name在地图上发现了一个神秘的标记。
标记的旁边写着：这里藏着一个大大的宝藏！
$name兴奋极了，马上收拾好背包，准备去寻宝。
$name走过了茂密的森林，遇到了一只会说话的小松鼠。小松鼠说：「前面的路很危险，但你只要勇敢，就一定能通过！」
$name点点头，继续前进。
$name又走过了一条小河，河里的小鱼们跳起来和$name打招呼。
最后，$name来到了一个大大的山洞前面。
山洞里黑漆漆的，什么也看不见。
可是$name一点也不害怕，因为$name是一个勇敢的小冒险家！
$name点起火把，走进了山洞。
在山洞的最深处，$name发现了一个闪闪发光的宝箱！
打开宝箱一看，里面装满了金币，还有一本神奇的故事书。
更重要的是，$name发现了一个道理：勇敢和坚持，是最重要的宝藏！
回到家里，$name把今天的冒险故事讲给了爸爸妈妈听。
晚上，$name躺在床上，想着明天又会有什么新的冒险呢？
晚安，小冒险家$name。✨🗺️''';
  }

  String _buildWarmStory(String title, String scene, String character, String name, int age, String interest) {
    return '''$scene，住着一个幸福的家庭。
家里有一个叫$name的小朋友，今年$age岁了，最喜欢的事情就是$interest。
每天早上，妈妈都会给$name准备一份香喷喷的早餐。
每天晚上，爸爸都会给$name讲一个温馨的小故事。
今天，$name在幼儿园里表现得特别好。老师给$name发了一朵小红花。
$name开心极了，回到家里第一件事就是告诉爸爸妈妈。
晚上，妈妈给$name做了最爱吃的晚饭。
吃完晚饭，爸爸带着$name去楼下散散步。
一路上，$name看到了好多好多的星星，一闪一闪地挂在天上。
回家后，妈妈给$name洗了个暖暖的澡，爸爸给$name换上了软绵绵的睡衣。
$name躺到了温暖的小床上，抱着最心爱的小娃娃。
妈妈轻轻地亲了亲$name的额头，爸爸给$name盖好了被子。
晚安，$name，明天又是美好的一天。✨🌙''';
  }

  String _buildEducationalStory(String title, String scene, String character, String name, int age, String interest) {
    return '''$scene，住着$character。
$character的名字叫$name，今年$age岁了，是一个可爱的小朋友。
今天，$name在幼儿园里学习了一个非常重要的道理。
老师说：「小朋友们，我们要学会分享。把好东西和好朋友们一起分享，快乐就会加倍哦！」
$name认真地听着，心里记着这句话。
下午，妈妈给$name买了一包甜甜的糖果。
$name看着糖果，想起了老师说的话。
于是，$name把糖果分给了邻居家的小弟弟和小妹妹。
小弟弟和小妹妹开心地说：「谢谢你，$name！」
$name也开心地笑了，心里甜甜的。
妈妈看到了，笑着说：「$name真是一个懂事的好孩子！」
晚上，$name躺在床上想：原来分享真的会带来快乐呀！
以后，$name还要把更多好东西和朋友们一起分享。
晚安，会分享的小宝贝$name。
愿你每天都能学到新的好东西。✨📚''';
  }

  // ========== 会员相关 ==========

  /// 获取会员套餐列表
  List<Map<String, dynamic>> getVipPlans() {
    return [
      {'plan_type': 'weekly', 'name': '7天会员', 'price': 9.9, 'description': '7天无限生成故事，畅享故事库', 'duration_days': 7},
      {'plan_type': 'monthly', 'name': '月度会员', 'price': 19.9, 'description': '30天无限生成故事，畅享故事库', 'duration_days': 30},
      {'plan_type': 'quarterly', 'name': '季度会员', 'price': 49.9, 'description': '90天无限生成故事，畅享故事库', 'duration_days': 90},
      {'plan_type': 'yearly', 'name': '年度会员', 'price': 168.0, 'description': '365天无限生成故事，畅享故事库', 'duration_days': 365},
    ];
  }

  /// 获取当前会员状态
  Future<Map<String, dynamic>> getVipStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isVip = prefs.getBool('vip_is_vip') ?? false;
    final expireStr = prefs.getString('vip_expire');
    final freeGenerateCount = prefs.getInt('free_generate_count') ?? 0;
    final freeListenCount = prefs.getInt('free_listen_count') ?? 0;

    DateTime? expireTime;
    if (expireStr != null) {
      expireTime = DateTime.tryParse(expireStr);
    }

    return {
      'code': 200,
      'data': {
        'is_vip': isVip,
        'vip_expire_date': expireTime?.toIso8601String(),
        'remaining_free_generate': isVip ? -1 : (3 - freeGenerateCount),
        'remaining_free_listen': isVip ? -1 : (3 - freeListenCount),
        'used_generate': freeGenerateCount,
        'used_listen': freeListenCount,
      }
    };
  }

  /// 激活会员
  Future<Map<String, dynamic>> activateVip(String planType) async {
    final prefs = await SharedPreferences.getInstance();
    int days = 30;
    switch (planType) {
      case 'weekly':
        days = 7;
        break;
      case 'monthly':
        days = 30;
        break;
      case 'quarterly':
        days = 90;
        break;
      case 'yearly':
        days = 365;
        break;
    }

    final expireTime = DateTime.now().add(Duration(days: days));
    await prefs.setBool('vip_is_vip', true);
    await prefs.setString('vip_expire', expireTime.toIso8601String());

    return {'code': 200, 'message': 'success', 'data': null};
  }

  /// 记录一次收听
  Future<bool> recordListen() async {
    final prefs = await SharedPreferences.getInstance();
    final isVip = prefs.getBool('vip_is_vip') ?? false;
    if (isVip) return true;

    final used = prefs.getInt('free_listen_count') ?? 0;
    if (used >= 3) return false;

    await prefs.setInt('free_listen_count', used + 1);
    return true;
  }
}
