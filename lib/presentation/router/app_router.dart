import 'package:go_router/go_router.dart';
import '../screens/dashboard_screen.dart';
import '../screens/customers_screen.dart';
import '../screens/customer_ledger_screen.dart';
import '../screens/add_edit_customer_screen.dart';
import '../screens/add_edit_entry_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/customers',
      builder: (context, state) => const CustomersScreen(),
    ),
    GoRoute(
      path: '/customers/:id',
      builder: (context, state) {
        final customerId = state.pathParameters['id']!;
        return CustomerLedgerScreen(customerId: customerId);
      },
    ),
    GoRoute(
      path: '/customers/:id/add-entry',
      builder: (context, state) {
        final customerId = state.pathParameters['id']!;
        return AddEditEntryScreen(customerId: customerId);
      },
    ),
    GoRoute(
      path: '/entries/:entryId/edit',
      builder: (context, state) {
        final entryId = state.pathParameters['entryId']!;
        return AddEditEntryScreen(entryId: entryId);
      },
    ),
    GoRoute(
      path: '/add-customer',
      builder: (context, state) => const AddEditCustomerScreen(),
    ),
    GoRoute(
      path: '/edit-customer/:id',
      builder: (context, state) {
        final customerId = state.pathParameters['id']!;
        return AddEditCustomerScreen(customerId: customerId);
      },
    ),
  ],
);
