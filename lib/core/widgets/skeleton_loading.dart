import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SkeletonListLoading extends StatelessWidget {
  final int itemCount;
  const SkeletonListLoading({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        itemCount: itemCount,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const CircleAvatar(radius: 24, child: Icon(Icons.person)),
              title: const Text('العنوان الرئيسي للعنصر هنا'),
              subtitle: const Text('هذا النص هو نص تجريبي يظهر كعنصر تحميل'),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          );
        },
      ),
    );
  }
}

class SkeletonCardLoading extends StatelessWidget {
  final int itemCount;
  const SkeletonCardLoading({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: List.generate(itemCount, (index) => 
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('العنوان الرئيسي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text('وصف للعنصر يمتد على عدة أسطر لإظهار حالة التحميل بشكل جيد وواضح للمستخدم.'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('التاريخ: 2024-01-01'),
                        Icon(Icons.more_vert),
                      ],
                    )
                  ],
                ),
              ),
            )
          ),
        ),
      ),
    );
  }
}

class SkeletonProfileLoading extends StatelessWidget {
  const SkeletonProfileLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 16),
            const Text('اسم المستخدم', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('معلومات المستخدم'),
            const SizedBox(height: 32),
            ...List.generate(4, (index) => 
              const ListTile(
                leading: Icon(Icons.info),
                title: Text('عنوان المعلومة'),
                subtitle: Text('قيمة المعلومة'),
              )
            ),
          ],
        ),
      ),
    );
  }
}

// Skeleton for Student/Teacher Home Tab
class SkeletonHomeLoading extends StatelessWidget {
  const SkeletonHomeLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Welcome Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const CircleAvatar(radius: 28, child: Icon(Icons.person)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('أهلاً بك في التطبيق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('معلومات إضافية عن المستخدم'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Cards
            ...List.generate(3, (index) =>
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('عنوان القسم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(3, (i) =>
                        const Column(
                          children: [
                            Icon(Icons.info, size: 24),
                            SizedBox(height: 4),
                            Text('بيانات'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Skeleton for Students Grid
class SkeletonStudentsGrid extends StatelessWidget {
  final int itemCount;
  const SkeletonStudentsGrid({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircleAvatar(radius: 32, child: Icon(Icons.person, size: 32)),
                SizedBox(height: 12),
                Text('اسم الطالب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('الصف الدراسي'),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, size: 16),
                    SizedBox(width: 4),
                    Text('4.5'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Skeleton for Notifications
class SkeletonNotifications extends StatelessWidget {
  final int itemCount;
  const SkeletonNotifications({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6E6FA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_rounded, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('عنوان الإشعار', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('محتوى الإشعار يظهر هنا مع تفاصيل إضافية عن الحدث'),
                      SizedBox(height: 8),
                      Text('2024-01-15 • 09:30 AM', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Skeleton for Teacher Daily Reports
class SkeletonDailyReports extends StatelessWidget {
  final int itemCount;
  const SkeletonDailyReports({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('حاضر'),
                    ),
                    Row(
                      children: const [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('اسم الطالب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('الصف الدراسي', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        SizedBox(width: 10),
                        CircleAvatar(radius: 20, child: Icon(Icons.person)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    Row(
                      children: [
                        Text('5', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Icon(Icons.star_rounded, color: Color(0xFFFFCC00), size: 18),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 4),
                        Text('استراحة'),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 4),
                        Text('وجبة'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
