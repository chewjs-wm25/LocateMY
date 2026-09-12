import 'package:flutter/material.dart';

import 'package:locatemy/core/app_state.dart';
import 'package:locatemy/core/models/location.dart';
import 'package:locatemy/core/widgets/app_scaffold.dart';
import 'package:locatemy/core/widgets/common_widgets.dart';

class SavedPage extends StatelessWidget {
  const SavedPage({required this.state, super.key});
  final LocateMyState state;

  @override
  Widget build(BuildContext context) => LocateMyScaffold(
    state: state,
    title: '已保存地点',
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        searchField(() {}),
        const SizedBox(height: 12),
        placeRow('吉隆坡', '吉隆坡联邦直辖区', '定位', () {
          state.selectPlace(Place.kl);
          state.map();
        }),
        placeRow('乔治市（槟城）', '东北县，槟城', state.saved ? '已保存' : '78/100', () {
          state.selectPlace(Place.penang);
          state.map();
        }),
        const SizedBox(height: 28),
        const Center(
          child: Text('暂无更多地点', style: TextStyle(color: Colors.black54)),
        ),
      ],
    ),
  );
}

class ReportPage extends StatelessWidget {
  const ReportPage({required this.state, super.key});
  final LocateMyState state;

  @override
  Widget build(BuildContext context) => LocateMyScaffold(
    state: state,
    title: '上报隐患',
    actions: [IconButton(onPressed: state.back, icon: const Icon(Icons.close))],
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('位置：${state.selected.name}（预设地点）'),
        const SizedBox(height: 16),
        section('隐患类型'),
        Wrap(
          spacing: 8,
          runSpacing: 7,
          children: ['水灾', '治安', '交通', '基础设施', '其他']
              .map(
                (value) => FilterChip(
                  label: Text(value),
                  selected: value == '水灾',
                  onSelected: (_) {},
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(labelText: '标题 *', hintText: '简要说明发生了什么'),
        ),
        const SizedBox(height: 12),
        const TextField(
          maxLines: 4,
          decoration: InputDecoration(
            labelText: '详细描述',
            hintText: '补充有助于他人判断的资讯…',
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () => state.go(PageId.reports),
          child: const Text('提交报告（仅作页面跳转）'),
        ),
      ],
    ),
  );
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({required this.state, super.key});
  final LocateMyState state;

  @override
  Widget build(BuildContext context) => LocateMyScaffold(
    state: state,
    title: '我的隐患报告',
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '这些均为演示记录，未被提交到任何服务。',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        appCard(
          context,
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.water_drop_outlined),
            title: Text('水灾 · 2026/08/18'),
            subtitle: Text('雨后排水沟积水较多\n乔治市 · 示例报告'),
          ),
        ),
        const SizedBox(height: 8),
        appCard(
          context,
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.traffic_outlined),
            title: Text('交通 · 2026/08/01'),
            subtitle: Text('路口晚高峰拥堵\n吉隆坡 · 示例报告'),
          ),
        ),
      ],
    ),
  );
}

class AccountPage extends StatelessWidget {
  const AccountPage({required this.state, super.key});
  final LocateMyState state;

  @override
  Widget build(BuildContext context) => LocateMyScaffold(
    state: state,
    title: '账户',
    up: false,
    nav: true,
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CircleAvatar(radius: 34, child: Icon(Icons.person, size: 36)),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            '林小姐',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        const Center(
          child: Text(
            'lin@example.com',
            style: TextStyle(color: Colors.black54),
          ),
        ),
        const Center(
          child: Chip(
            avatar: Icon(Icons.verified, size: 16),
            label: Text('邮箱已验证'),
          ),
        ),
        const SizedBox(height: 20),
        section('我的内容'),
        ListTile(
          leading: const Icon(Icons.home_work_outlined),
          title: const Text('房产实勘档案'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => state.go(PageId.properties),
        ),
        ListTile(
          leading: const Icon(Icons.warning_amber_outlined),
          title: const Text('我的隐患报告'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => state.go(PageId.reports),
        ),
        const Divider(),
        section('地点适配设置'),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.tune),
          title: Text('评估偏好'),
          subtitle: Text('安全、成本、日常便利、公共交通、基础设施 · 示例已设置'),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.account_balance_wallet_outlined),
          title: Text('当前评估预案'),
          subtitle: Text('一人租住 · 示例预案（用于地点适配度与预算压力）'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('语言'),
          subtitle: const Text('中文'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('退出登录'),
          onTap: () => state.go(PageId.login),
        ),
        const SizedBox(height: 18),
        notice(),
      ],
    ),
  );
}

class LoginPage extends StatelessWidget {
  const LoginPage({required this.state, super.key});
  final LocateMyState state;

  @override
  Widget build(BuildContext context) => LocateMyScaffold(
    state: state,
    title: 'LocateMY',
    up: false,
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.location_on, size: 64, color: Color(0xff006c68)),
            const Center(
              child: Text(
                '找到更适合生活的地方',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            const SizedBox(height: 32),
            Text('欢迎回来', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: '电子邮箱',
                hintText: 'name@example.com',
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: '密码'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: state.home, child: const Text('登录（演示）')),
            TextButton(
              onPressed: () => state.go(PageId.register),
              child: const Text('还没有账户？创建账户'),
            ),
          ],
        ),
      ),
    ),
  );
}

class RegisterPage extends StatelessWidget {
  const RegisterPage({required this.state, super.key});
  final LocateMyState state;

  @override
  Widget build(BuildContext context) => LocateMyScaffold(
    state: state,
    title: '创建账户',
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const TextField(
          decoration: InputDecoration(labelText: '用户名', hintText: '输入您的姓名'),
        ),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(
            labelText: '电子邮箱',
            hintText: 'name@example.com',
          ),
        ),
        const SizedBox(height: 12),
        const TextField(
          obscureText: true,
          decoration: InputDecoration(
            labelText: '密码',
            helperText: '至少 8 位，包含大小写字母、数字和符号',
          ),
        ),
        const SizedBox(height: 12),
        const TextField(
          obscureText: true,
          decoration: InputDecoration(labelText: '确认密码'),
        ),
        const SizedBox(height: 18),
        FilledButton(onPressed: state.home, child: const Text('创建账户（演示）')),
        TextButton(
          onPressed: () => state.go(PageId.login),
          child: const Text('已有账户？登录'),
        ),
      ],
    ),
  );
}
