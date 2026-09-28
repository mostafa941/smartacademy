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
