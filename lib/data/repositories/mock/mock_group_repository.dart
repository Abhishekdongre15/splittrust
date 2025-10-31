import 'dart:async';

import '../../../domain/entities/activity_event.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/group.dart';
import '../../../domain/entities/settlement.dart';
import '../group_repository.dart';

class MockGroupRepository implements GroupRepository {
  MockGroupRepository() {
    _seed();
  }

  final _groups = <Group>[];
  final _activity = <ActivityEvent>[];

  void _seed() {
    final now = DateTime.now().toUtc();

    final membersTrip = [
      GroupMember(uid: 'user_aqua', displayName: 'AquaFire Team', role: GroupRole.admin, joinedAt: now.subtract(const Duration(days: 60))),
      GroupMember(uid: 'uid_anna', displayName: 'Anna', role: GroupRole.member, joinedAt: now.subtract(const Duration(days: 58))),
      GroupMember(uid: 'uid_ben', displayName: 'Ben', role: GroupRole.member, joinedAt: now.subtract(const Duration(days: 58))),
    ];

    final goaExpenses = [
      Expense(
        id: 'exp_1',
        title: 'Villa Booking',
        amount: 42000,
        currency: 'INR',
        amountBase: 42000,
        payerUid: 'user_aqua',
        participants: const [
          ExpenseParticipant(uid: 'user_aqua', shareBase: 14000, shareOriginal: 14000),
          ExpenseParticipant(uid: 'uid_anna', shareBase: 14000, shareOriginal: 14000),
          ExpenseParticipant(uid: 'uid_ben', shareBase: 14000, shareOriginal: 14000),
        ],
        splitMode: SplitMode.equal,
        category: ExpenseCategory.travel,
        createdBy: 'user_aqua',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 29, hours: 20)),
        notes: '3 nights stay near Baga',
      ),
      Expense(
        id: 'exp_2',
        title: 'Scuba Diving',
        amount: 360.00,
        currency: 'USD',
        amountBase: 29900,
        payerUid: 'uid_anna',
        participants: const [
          ExpenseParticipant(uid: 'user_aqua', shareBase: 9966.67, shareOriginal: 120),
          ExpenseParticipant(uid: 'uid_anna', shareBase: 9966.67, shareOriginal: 120),
          ExpenseParticipant(uid: 'uid_ben', shareBase: 9966.66, shareOriginal: 120),
        ],
        splitMode: SplitMode.percent,
        category: ExpenseCategory.other,
        createdBy: 'uid_anna',
        createdAt: now.subtract(const Duration(days: 29)),
        updatedAt: now.subtract(const Duration(days: 29)),
        fx: FxSnapshot(from: 'USD', to: 'INR', rate: 83.05, capturedAt: now.subtract(const Duration(days: 29, hours: 1))),
        notes: 'Converted at booking time',
      ),
      Expense(
        id: 'exp_3',
        title: 'Airport Taxi',
        amount: 2100,
        currency: 'INR',
        amountBase: 2100,
        payerUid: 'uid_ben',
        participants: const [
          ExpenseParticipant(uid: 'user_aqua', shareBase: 700, shareOriginal: 700),
          ExpenseParticipant(uid: 'uid_anna', shareBase: 700, shareOriginal: 700),
          ExpenseParticipant(uid: 'uid_ben', shareBase: 700, shareOriginal: 700),
        ],
        splitMode: SplitMode.adjustment,
        category: ExpenseCategory.travel,
        createdBy: 'uid_ben',
        createdAt: now.subtract(const Duration(days: 28)),
        updatedAt: now.subtract(const Duration(days: 28)),
      ),
    ];

    final goaSettlements = [
      Settlement(
        id: 'set_1',
        fromUid: 'uid_ben',
        toUid: 'user_aqua',
        amount: 7000,
        currency: 'INR',
        method: SettlementMethod.upiIntent,
        reference: 'UPI-TRX-1001',
        createdBy: 'uid_ben',
        createdAt: now.subtract(const Duration(days: 14)),
      ),
    ];

    final membersFlat = [
      GroupMember(uid: 'user_aqua', displayName: 'AquaFire Team', role: GroupRole.admin, joinedAt: now.subtract(const Duration(days: 200))),
      GroupMember(uid: 'uid_charlie', displayName: 'Charlie', role: GroupRole.member, joinedAt: now.subtract(const Duration(days: 199))),
    ];

    final flatExpenses = [
      Expense(
        id: 'exp_4',
        title: 'Rent July',
        amount: 48000,
        currency: 'INR',
        amountBase: 48000,
        payerUid: 'uid_charlie',
        participants: const [
          ExpenseParticipant(uid: 'user_aqua', shareBase: 24000, shareOriginal: 24000),
          ExpenseParticipant(uid: 'uid_charlie', shareBase: 24000, shareOriginal: 24000),
        ],
        splitMode: SplitMode.exact,
        category: ExpenseCategory.rent,
        createdBy: 'uid_charlie',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 10)),
        receiptUrl: 'https://storage.splittrust.app/receipts/rent_july.pdf',
      ),
      Expense(
        id: 'exp_5',
        title: 'Electricity Bill',
        amount: 3200,
        currency: 'INR',
        amountBase: 3200,
        payerUid: 'user_aqua',
        participants: const [
          ExpenseParticipant(uid: 'user_aqua', shareBase: 1600, shareOriginal: 1600),
          ExpenseParticipant(uid: 'uid_charlie', shareBase: 1600, shareOriginal: 1600),
        ],
        splitMode: SplitMode.equal,
        category: ExpenseCategory.utilities,
        createdBy: 'user_aqua',
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 6)),
        notes: 'Due on 10th',
        ocr: ExpenseOcr(
          merchant: 'MSEB',
          date: now.subtract(const Duration(days: 7)),
          total: 3200,
          currency: 'INR',
          confidence: 0.82,
        ),
      ),
    ];

    final flatSettlements = [
      Settlement(
        id: 'set_2',
        fromUid: 'user_aqua',
        toUid: 'uid_charlie',
        amount: 12000,
        currency: 'INR',
        method: SettlementMethod.cash,
        createdBy: 'user_aqua',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Settlement(
        id: 'set_3',
        fromUid: 'user_aqua',
        toUid: 'uid_charlie',
        amount: 12000,
        currency: 'INR',
        method: SettlementMethod.cash,
        createdBy: 'user_aqua',
        createdAt: now.subtract(const Duration(days: 1)),
        reversedBy: 'uid_charlie',
      ),
    ];

    _groups
      ..add(
        Group(
          id: 'group_goa',
          name: 'Goa Getaway',
          type: GroupType.trip,
          baseCurrency: 'INR',
          members: membersTrip,
          expenses: goaExpenses,
          settlements: goaSettlements,
          createdAt: now.subtract(const Duration(days: 60)),
          updatedAt: now.subtract(const Duration(days: 1)),
          note: 'Team offsite planning',
        ),
      )
      ..add(
        Group(
          id: 'group_flat',
          name: 'Koramangala Flat',
          type: GroupType.house,
          baseCurrency: 'INR',
          members: membersFlat,
          expenses: flatExpenses,
          settlements: flatSettlements,
          createdAt: now.subtract(const Duration(days: 200)),
          updatedAt: now.subtract(const Duration(days: 1)),
          note: 'Monthly shared living costs',
        ),
      );

    _activity
      ..addAll([
        ActivityEvent(
          id: 'act_1',
          type: ActivityType.expenseAdded,
          title: 'Anna added Scuba Diving',
          subtitle: 'Goa Getaway',
          amountText: '₹29,900',
          timestamp: now.subtract(const Duration(days: 29)),
          actor: 'Anna',
        ),
        ActivityEvent(
          id: 'act_2',
          type: ActivityType.settlementAdded,
          title: 'Ben settled with AquaFire Team',
          subtitle: 'Goa Getaway',
          amountText: '₹7,000',
          timestamp: now.subtract(const Duration(days: 14)),
          actor: 'Ben',
        ),
        ActivityEvent(
          id: 'act_3',
          type: ActivityType.planChanged,
          title: 'Plan upgraded to Gold',
          subtitle: 'More automation unlocked',
          amountText: null,
          timestamp: now.subtract(const Duration(days: 10)),
          actor: 'AquaFire Team',
        ),
        ActivityEvent(
          id: 'act_4',
          type: ActivityType.expenseAdded,
          title: 'Rent July logged',
          subtitle: 'Koramangala Flat',
          amountText: '₹48,000',
          timestamp: now.subtract(const Duration(days: 10)),
          actor: 'Charlie',
        ),
        ActivityEvent(
          id: 'act_5',
          type: ActivityType.expenseAdded,
          title: 'Electricity Bill auto-filled via OCR',
          subtitle: 'Koramangala Flat',
          amountText: '₹3,200',
          timestamp: now.subtract(const Duration(days: 6)),
          actor: 'SplitTrust OCR',
        ),
      ]);
  }

  @override
  Future<List<Group>> getGroupsForUser(String uid) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return List<Group>.from(_groups);
  }

  @override
  Future<Group> getGroupById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _groups.firstWhere((g) => g.id == id);
  }

  @override
  Future<List<ActivityEvent>> recentActivity(String uid) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return List<ActivityEvent>.from(_activity)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}
