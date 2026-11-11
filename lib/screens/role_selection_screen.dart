import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'auth_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppConstants.emeraldBackgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFF1E3A5F),
                          Color(0xFF0A1118),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppConstants.goldAccent, width: 2.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.menu_book_rounded,
                          size: 54,
                          color: AppConstants.goldAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'سَفَرَة',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppConstants.goldAccent.withOpacity(0.45)),
                    ),
                    child: const Text(
                      'النظام المؤسسي الذكي لإدارة ومتابعة حلقات تحفيظ القرآن الكريم',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.lightGold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildRoleCard(
                    context,
                    title: 'مدير مركز / مسجد',
                    subtitle: 'إدارة الحلقات والمعلمين، استعراض إحصائيات الطلاب وتصدير تقارير المنظمات',
                    icon: Icons.admin_panel_settings_rounded,
                    role: AppConstants.roleAdmin,
                  ),
                  const SizedBox(height: 16),
                  _buildRoleCard(
                    context,
                    title: 'معلم حلقة (تابع لإدارة)',
                    subtitle: 'تسجيل الدخول بحساب المركز ومزامنة بيانات الحلقة والحضور والتسميع',
                    icon: Icons.groups_rounded,
                    role: AppConstants.roleManagedTeacher,
                  ),
                  const SizedBox(height: 16),
                  _buildRoleCard(
                    context,
                    title: 'معلم مستقل',
                    subtitle: 'إنشاء حساب مستقل لإدارة حلقتك الخاصة مع تقارير أولياء الأمور والنسخ السحابي',
                    icon: Icons.person_pin_rounded,
                    role: AppConstants.roleIndependentTeacher,
                  ),
                  const SizedBox(height: 34),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1118).withOpacity(0.75),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppConstants.goldAccent.withOpacity(0.6)),
                    ),
                    child: const Text(
                      'إعداد وتطوير: حاتم علي',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppConstants.goldAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String role,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF1A2F4B),
            Color(0xFF101C2E),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppConstants.goldAccent, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AuthScreen(
                  role: role,
                  allowRegister: role != AppConstants.roleManagedTeacher,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppConstants.goldAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppConstants.goldAccent, width: 1),
                  ),
                  child: Icon(
                    icon,
                    size: 30,
                    color: AppConstants.goldAccent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.white70,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: AppConstants.goldAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
