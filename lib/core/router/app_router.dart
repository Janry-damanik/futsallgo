import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_page.dart';
import '../../features/admin/admin_page.dart';
import '../../features/booking/booking_page.dart';
import '../../features/checkout/checkout_page.dart';
import '../../features/history/history_page.dart';
import '../../features/home/home_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/splash/splash_screen.dart';
import '../models/booking_summary.dart';
import 'routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.booking,
        builder: (context, state) =>
            BookingPage(initialCourtName: state.extra as String?),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => const CheckoutPage(
          booking: BookingSummary(
            fieldName: 'Lapangan 1',
            fieldLocation: 'Jl. Merdeka No. 12',
            date: 'Senin, 12 Agustus',
            time: '18.00 - 19.00',
            price: 'Rp 180.000',
            total: 'Rp 180.000',
            status: 'Menunggu pembayaran',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  );
});
