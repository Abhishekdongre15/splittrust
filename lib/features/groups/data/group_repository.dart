import 'dart:async';

import '../models/group_models.dart';

class GroupDataSnapshot {
  const GroupDataSnapshot({required this.groups, required this.directory});

  final List<GroupDetail> groups;
  final List<MemberProfile> directory;
}

abstract class GroupRepository {
  String get currentUserId;

  Future<GroupDataSnapshot> load();

  MemberProfile ensureMember(String displayName);

  Future<GroupDetail> createGroup({
    required String name,
    required String baseCurrency,
    required List<MemberProfile> members,
    String? note,
  });

  Future<GroupDetail> addEqualExpense({
    required String groupId,
    required String title,
    required double amount,
    required String paidBy,
    required List<String> participantIds,
    required String category,
    String? notes,
    DateTime? createdAt,
  });

  Future<GroupDetail> recordSettlement({
    required String groupId,
    required String fromMemberId,
    required String toMemberId,
    required double amount,
    required String method,
    String? reference,
    DateTime? recordedAt,
  });

  Future<GroupDetail> updateSimplifyDebts({required String groupId, required bool simplify});

  Future<GroupDetail> updateDefaultSplit({
    required String groupId,
    required GroupDefaultSplitStrategy strategy,
  });

  Future<GroupDetail> addMember({
    required String groupId,
    required MemberProfile member,
    GroupRole role = GroupRole.member,
  });

  Future<GroupDetail> removeMember({
    required String groupId,
    required String memberId,
  });

  Future<GroupDetail> updateBaseCurrency({
    required String groupId,
    required String baseCurrency,
  });

  Future<GroupDetail?> leaveGroup({required String groupId, required String memberId});

  Future<void> deleteGroup({required String groupId});
}

class MockGroupRepository implements GroupRepository {
  MockGroupRepository() {
    _seed();
  }

  final Map<String, MemberProfile> _memberDirectory = {};
  final List<GroupDetail> _groups = [];
  late final String _currentUserId;

  @override
  String get currentUserId => _currentUserId;

  @override
  Future<GroupDataSnapshot> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return GroupDataSnapshot(
      groups: List<GroupDetail>.unmodifiable(_groups),
      directory: List<MemberProfile>.unmodifiable(_memberDirectory.values),
    );
  }

  @override
  MemberProfile ensureMember(String displayName) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Display name cannot be empty');
    }
    for (final entry in _memberDirectory.entries) {
      if (entry.value.displayName.toLowerCase() == trimmed.toLowerCase()) {
        return entry.value;
      }
    }
    final id = _generateId('mem');
    final member = MemberProfile(id: id, displayName: trimmed);
    _memberDirectory[id] = member;
    return member;
  }

  @override
  Future<GroupDetail> createGroup({
    required String name,
    required String baseCurrency,
    required List<MemberProfile> members,
    String? note,
  }) async {
    if (members.length < 2) {
      throw StateError('Groups require at least two members');
    }
    final id = _generateId('grp');
    final now = DateTime.now();
    final uniqueMembers = <String, MemberProfile>{};
    for (final member in members) {
      final ensured = ensureMember(member.displayName);
      uniqueMembers[ensured.id] = ensured;
    }
    final orderedMembers = uniqueMembers.values.toList();
    final groupMembers = <GroupMember>[];
    for (var index = 0; index < orderedMembers.length; index++) {
      final profile = orderedMembers[index];
      groupMembers.add(GroupMember.fromProfile(
        profile,
        role: index == 0 ? GroupRole.admin : GroupRole.member,
      ));
    }
    final history = <GroupHistoryEntry>[
      GroupHistoryEntry(
        id: _generateId('hist'),
        type: GroupHistoryType.groupCreated,
        title: '$name created',
        subtitle: '${groupMembers.length} members joined this space',
        timestamp: now,
      ),
    ];
    for (final member in groupMembers) {
      history.add(
        GroupHistoryEntry(
          id: _generateId('hist'),
          type: GroupHistoryType.memberAdded,
          title: '${member.displayName} joined',
          subtitle: member.role == GroupRole.admin ? 'Appointed as admin' : 'Added as member',
          timestamp: now,
        ),
      );
    }
    final group = GroupDetail(
      id: id,
      name: name.trim(),
      baseCurrency: baseCurrency,
      members: groupMembers,
      expenses: const [],
      settlements: const [],
      history: history,
      simplifyDebts: true,
      defaultSplitStrategy: GroupDefaultSplitStrategy.paidByYouEqual,
      note: note?.trim().isEmpty ?? true ? null : note?.trim(),
    );
    _groups.add(group);
    return group;
  }

  @override
  Future<GroupDetail> addEqualExpense({
    required String groupId,
    required String title,
    required double amount,
    required String paidBy,
    required List<String> participantIds,
    required String category,
    String? notes,
    DateTime? createdAt,
  }) async {
    final index = _groups.indexWhere((group) => group.id == groupId);
    if (index == -1) {
      throw StateError('Group not found');
    }
    final group = _groups[index];
    if (participantIds.isEmpty) {
      throw StateError('At least one participant is required');
    }
    final now = createdAt ?? DateTime.now();
    final sanitizedParticipants = participantIds.toSet().toList();
    final shares = _buildEqualShares(roundBankers(amount), sanitizedParticipants);
    final expense = GroupExpense(
      id: _generateId('exp'),
      title: title.trim(),
      amount: roundBankers(amount),
      currency: group.baseCurrency,
      amountBase: roundBankers(amount),
      paidBy: paidBy,
      participantIds: sanitizedParticipants,
      shares: shares,
      category: category,
      createdAt: now,
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
    );
    final updatedExpenses = List<GroupExpense>.from(group.expenses)..add(expense);
    final updatedHistory = List<GroupHistoryEntry>.from(group.history)
      ..add(
        GroupHistoryEntry(
          id: _generateId('hist'),
          type: GroupHistoryType.expenseAdded,
          title: '${expense.title} logged',
          subtitle: '${_nameForMember(group, expense.paidBy)} paid ${group.baseCurrency} ${expense.amount.toStringAsFixed(2)}',
          timestamp: now,
        ),
      );
    final updatedGroup = group.copyWith(expenses: updatedExpenses, history: updatedHistory);
    _groups[index] = updatedGroup;
    return updatedGroup;
  }

  @override
  Future<GroupDetail> recordSettlement({
    required String groupId,
    required String fromMemberId,
    required String toMemberId,
    required double amount,
    required String method,
    String? reference,
    DateTime? recordedAt,
  }) async {
    final index = _groups.indexWhere((group) => group.id == groupId);
    if (index == -1) {
      throw StateError('Group not found');
    }
    final group = _groups[index];
    if (fromMemberId == toMemberId) {
      throw StateError('Cannot settle with the same member');
    }
    final now = recordedAt ?? DateTime.now();
    final settlement = GroupSettlement(
      id: _generateId('set'),
      fromMemberId: fromMemberId,
      toMemberId: toMemberId,
      amount: roundBankers(amount),
      method: method,
      recordedAt: now,
      reference: reference?.trim().isEmpty ?? true ? null : reference?.trim(),
    );
    final updatedSettlements = List<GroupSettlement>.from(group.settlements)..add(settlement);
    final subtitle = '${_nameForMember(group, fromMemberId)} paid ${group.baseCurrency} ${settlement.amount.toStringAsFixed(2)} to ${_nameForMember(group, toMemberId)} via $method';
    final updatedHistory = List<GroupHistoryEntry>.from(group.history)
      ..add(
        GroupHistoryEntry(
          id: _generateId('hist'),
          type: GroupHistoryType.settlementRecorded,
          title: 'Settlement recorded',
          subtitle: subtitle,
          timestamp: now,
        ),
      );
    final updatedGroup = group.copyWith(settlements: updatedSettlements, history: updatedHistory);
    _groups[index] = updatedGroup;
    return updatedGroup;
  }

  @override
  Future<GroupDetail> updateSimplifyDebts({required String groupId, required bool simplify}) async {
    final index = _groups.indexWhere((group) => group.id == groupId);
    if (index == -1) {
      throw StateError('Group not found');
    }
    final group = _groups[index];
    final now = DateTime.now();
    final history = List<GroupHistoryEntry>.from(group.history)
      ..add(
        GroupHistoryEntry(
          id: _generateId('hist'),
          type: GroupHistoryType.note,
          title: simplify ? 'Simplify group debts enabled' : 'Simplify group debts disabled',
          subtitle: 'Updated by ${_nameForMember(group, _currentUserId)}',
          timestamp: now,
        ),
      );
    final updated = group.copyWith(simplifyDebts: simplify, history: history);
    _groups[index] = updated;
    return updated;
  }

  @override
  Future<GroupDetail> updateDefaultSplit({
    required String groupId,
    required GroupDefaultSplitStrategy strategy,
  }) async {
    final index = _groups.indexWhere((group) => group.id == groupId);
    if (index == -1) {
      throw StateError('Group not found');
    }
    final group = _groups[index];
    final history = List<GroupHistoryEntry>.from(group.history)
      ..add(
        GroupHistoryEntry(
          id: _generateId('hist'),
          type: GroupHistoryType.note,
          title: 'Default split updated',
          subtitle: '${strategy.title} • ${_nameForMember(group, _currentUserId)}',
          timestamp: DateTime.now(),
        ),
      );
    final updated = group.copyWith(defaultSplitStrategy: strategy, history: history);
    _groups[index] = updated;
    return updated;
  }

  @override
  Future<GroupDetail> addMember({
    required String groupId,
    required MemberProfile member,
    GroupRole role = GroupRole.member,
  }) async {
    final index = _groups.indexWhere((group) => group.id == groupId);
    if (index == -1) {
      throw StateError('Group not found');
    }
    final group = _groups[index];
    final ensured = ensureMember(member.displayName);
    if (group.members.any((existing) => existing.id == ensured.id)) {
      throw StateError('${ensured.displayName} is already in this group');
    }
    final newMember = GroupMember.fromProfile(ensured, role: role);
    final updatedMembers = List<GroupMember>.from(group.members)..add(newMember);
    final addedBy = _memberDirectory[_currentUserId]?.displayName ?? 'Admin';
    final history = List<GroupHistoryEntry>.from(group.history)
      ..add(
        GroupHistoryEntry(
          id: _generateId('hist'),
          type: GroupHistoryType.memberAdded,
          title: '${newMember.displayName} joined',
          subtitle: role == GroupRole.admin ? 'Appointed as admin' : 'Invited by $addedBy',
          timestamp: DateTime.now(),
        ),
      );
    final updated = group.copyWith(members: updatedMembers, history: history);
    _groups[index] = updated;
    return updated;
  }

  @override
  Future<GroupDetail> removeMember({
    required String groupId,
    required String memberId,
  }) async {
    final index = _groups.indexWhere((group) => group.id == groupId);
    if (index == -1) {
      throw StateError('Group not found');
    }
    final group = _groups[index];
    final member = group.memberById(memberId);
    if (member == null) {
      throw StateError('Member not found');
    }
    if (member.role == GroupRole.admin) {
      throw StateError('Transfer admin rights before removing this member');
    }
    final balance = group.balances[memberId];
    if (balance != null && balance.net.abs() > 0.01) {
      throw StateError('${member.displayName} still has an outstanding balance');
    }
    final updatedMembers = List<GroupMember>.from(group.members)
      ..removeWhere((existing) => existing.id == memberId);
    final history = List<GroupHistoryEntry>.from(group.history)
      ..add(
        GroupHistoryEntry(
          id: _generateId('hist'),
          type: GroupHistoryType.memberRemoved,
          title: '${member.displayName} removed',
          subtitle: 'Removed after settling balances',
          timestamp: DateTime.now(),
        ),
      );
    final updated = group.copyWith(members: updatedMembers, history: history);
    _groups[index] = updated;
    return updated;
  }

  @override
  Future<GroupDetail> updateBaseCurrency({
    required String groupId,
    required String baseCurrency,
  }) async {
    final index = _groups.indexWhere((group) => group.id == groupId);
    if (index == -1) {
      throw StateError('Group not found');
    }
    final group = _groups[index];
    if (group.baseCurrency == baseCurrency) {
      return group;
    }
    final updatedExpenses = group.expenses
        .map(
          (expense) => GroupExpense(
            id: expense.id,
            title: expense.title,
            amount: expense.amount,
            currency: baseCurrency,
            amountBase: expense.amountBase,
            paidBy: expense.paidBy,
            participantIds: List<String>.from(expense.participantIds),
            shares: List<ExpenseShare>.from(expense.shares),
            category: expense.category,
            createdAt: expense.createdAt,
            notes: expense.notes,
          ),
        )
        .toList();
    final history = List<GroupHistoryEntry>.from(group.history)
      ..add(
        GroupHistoryEntry(
          id: _generateId('hist'),
          type: GroupHistoryType.currencyChanged,
          title: 'Currency updated to $baseCurrency',
          subtitle: '${group.baseCurrency} → $baseCurrency',
          timestamp: DateTime.now(),
        ),
      );
    final updated = group.copyWith(
      baseCurrency: baseCurrency,
      expenses: updatedExpenses,
      history: history,
    );
    _groups[index] = updated;
    return updated;
  }

  @override
  Future<GroupDetail?> leaveGroup({required String groupId, required String memberId}) async {
    final index = _groups.indexWhere((group) => group.id == groupId);
    if (index == -1) {
      throw StateError('Group not found');
    }
    final group = _groups[index];
    final member = group.memberById(memberId);
    if (member == null) {
      throw StateError('Member not part of this group');
    }
    final balance = group.balances[memberId];
    final outstanding = balance?.net ?? 0;
    if (outstanding.abs() > 0.01) {
      throw StateError('You have outstanding balances in this group. Settle up before leaving.');
    }
    final updatedMembers = List<GroupMember>.from(group.members)
      ..removeWhere((element) => element.id == memberId);
    if (updatedMembers.isEmpty) {
      _groups.removeAt(index);
      return null;
    }
    if (!updatedMembers.any((element) => element.role == GroupRole.admin)) {
      updatedMembers[0] = updatedMembers[0].copyWith(role: GroupRole.admin);
    }
    final history = List<GroupHistoryEntry>.from(group.history)
      ..add(
        GroupHistoryEntry(
          id: _generateId('hist'),
          type: GroupHistoryType.note,
          title: '${member.displayName} left the group',
          subtitle: 'No outstanding balance',
          timestamp: DateTime.now(),
        ),
      );
    final updated = group.copyWith(members: updatedMembers, history: history);
    _groups[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteGroup({required String groupId}) async {
    final index = _groups.indexWhere((group) => group.id == groupId);
    if (index == -1) {
      throw StateError('Group not found');
    }
    _groups.removeAt(index);
  }

  void _seed() {
    final aqua = ensureMember('AquaFire Solutions');
    _currentUserId = aqua.id;
    final ben = ensureMember('Ben Mathews');
    final clara = ensureMember('Clara Singh');
    final divya = ensureMember('Divya Patel');
    final ethan = ensureMember('Ethan Brooks');
    final fiona = ensureMember('Fiona Desai');

    final goaMembers = [
      GroupMember.fromProfile(aqua, role: GroupRole.admin),
      GroupMember.fromProfile(ben),
      GroupMember.fromProfile(clara),
      GroupMember.fromProfile(divya),
    ];
    final goaExpenses = <GroupExpense>[];
    final goaSettlements = <GroupSettlement>[];
    final goaHistory = <GroupHistoryEntry>[];
    final now = DateTime.now();
    final goaId = _generateId('grp');

    goaHistory.add(
      GroupHistoryEntry(
        id: _generateId('hist'),
        type: GroupHistoryType.groupCreated,
        title: 'Goa Getaway created',
        subtitle: '4 members joined this space',
        timestamp: now.subtract(const Duration(days: 18)),
      ),
    );
    for (final member in goaMembers) {
      goaHistory.add(
        GroupHistoryEntry(
          id: _generateId('hist'),
          type: GroupHistoryType.memberAdded,
          title: '${member.displayName} joined',
          subtitle: member.role == GroupRole.admin ? 'Appointed as admin' : 'Added as member',
          timestamp: now.subtract(const Duration(days: 18, minutes: 5)),
        ),
      );
    }

    goaExpenses.addAll([
      _buildExpense(
        title: 'Beach Villa Stay',
        amount: 48000,
        baseCurrency: 'INR',
        paidBy: aqua.id,
        participantIds: goaMembers.map((m) => m.id).toList(),
        category: 'Travel',
        createdAt: now.subtract(const Duration(days: 16)),
        notes: '3 nights in Candolim',
      ),
      _buildExpense(
        title: 'Scuba Diving',
        amount: 29900,
        baseCurrency: 'INR',
        paidBy: clara.id,
        participantIds: [aqua.id, ben.id, clara.id],
        category: 'Activities',
        createdAt: now.subtract(const Duration(days: 15, hours: 3)),
        notes: 'Includes underwater photography',
      ),
      _buildExpense(
        title: 'Cafe Bodega Brunch',
        amount: 5400,
        baseCurrency: 'INR',
        paidBy: ben.id,
        participantIds: [ben.id, clara.id, divya.id],
        category: 'Food',
        createdAt: now.subtract(const Duration(days: 14, hours: 4)),
        notes: 'Sunday brunch special',
      ),
    ]);

    for (final expense in goaExpenses) {
      goaHistory.add(
        GroupHistoryEntry(
          id: _generateId('hist'),
          type: GroupHistoryType.expenseAdded,
          title: '${expense.title} logged',
          subtitle: '${_nameForMemberRaw(goaMembers, expense.paidBy)} paid INR ${expense.amount.toStringAsFixed(2)}',
          timestamp: expense.createdAt,
        ),
      );
    }

    goaSettlements.add(
      GroupSettlement(
        id: _generateId('set'),
        fromMemberId: ben.id,
        toMemberId: aqua.id,
        amount: 12500,
        method: 'upi_intent',
        recordedAt: now.subtract(const Duration(days: 7, hours: 2)),
        reference: 'UPI TXN4820',
      ),
    );
    goaHistory.add(
      GroupHistoryEntry(
        id: _generateId('hist'),
        type: GroupHistoryType.settlementRecorded,
        title: 'Settlement recorded',
        subtitle: 'Ben Mathews paid INR 12500.00 to AquaFire Solutions via upi_intent',
        timestamp: now.subtract(const Duration(days: 7, hours: 2)),
      ),
    );

    final goaGroup = GroupDetail(
      id: goaId,
      name: 'Goa Getaway',
      baseCurrency: 'INR',
      members: goaMembers,
      expenses: goaExpenses,
      settlements: goaSettlements,
      history: goaHistory,
      simplifyDebts: true,
      defaultSplitStrategy: GroupDefaultSplitStrategy.paidByYouEqual,
      note: 'Friends trip to Goa with villa stay and adventures.',
    );
    _groups.add(goaGroup);

    final officeMembers = [
      GroupMember.fromProfile(aqua, role: GroupRole.admin),
      GroupMember.fromProfile(ethan),
      GroupMember.fromProfile(fiona),
    ];
    final officeId = _generateId('grp');
    final officeExpenses = <GroupExpense>[
      _buildExpense(
        title: 'July Coworking Rent',
        amount: 1800,
        baseCurrency: 'USD',
        paidBy: aqua.id,
        participantIds: officeMembers.map((m) => m.id).toList(),
        category: 'Rent',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      _buildExpense(
        title: 'Team Lunch',
        amount: 210,
        baseCurrency: 'USD',
        paidBy: fiona.id,
        participantIds: officeMembers.map((m) => m.id).toList(),
        category: 'Food',
        createdAt: now.subtract(const Duration(days: 12)),
        notes: 'Celebrated closing the beta milestone',
      ),
    ];
    final officeHistory = <GroupHistoryEntry>[
      GroupHistoryEntry(
        id: _generateId('hist'),
        type: GroupHistoryType.groupCreated,
        title: 'HQ Expenses created',
        subtitle: '3 members joined this space',
        timestamp: now.subtract(const Duration(days: 30)),
      ),
      for (final member in officeMembers)
        GroupHistoryEntry(
          id: _generateId('hist'),
          type: GroupHistoryType.memberAdded,
          title: '${member.displayName} joined',
          subtitle: member.role == GroupRole.admin ? 'Appointed as admin' : 'Added as member',
          timestamp: now.subtract(const Duration(days: 30, minutes: 4)),
        ),
      for (final expense in officeExpenses)
        GroupHistoryEntry(
          id: _generateId('hist'),
          type: GroupHistoryType.expenseAdded,
          title: '${expense.title} logged',
          subtitle: '${_nameForMemberRaw(officeMembers, expense.paidBy)} paid USD ${expense.amount.toStringAsFixed(2)}',
          timestamp: expense.createdAt,
        ),
    ];
    final officeGroup = GroupDetail(
      id: officeId,
      name: 'HQ Expenses',
      baseCurrency: 'USD',
      members: officeMembers,
      expenses: officeExpenses,
      settlements: const [],
      history: officeHistory,
      simplifyDebts: false,
      defaultSplitStrategy: GroupDefaultSplitStrategy.splitByLastPayer,
      note: 'Shared workspace and team meals.',
    );
    _groups.add(officeGroup);
  }

  GroupExpense _buildExpense({
    required String title,
    required double amount,
    required String baseCurrency,
    required String paidBy,
    required List<String> participantIds,
    required String category,
    required DateTime createdAt,
    String? notes,
  }) {
    final sanitizedParticipants = participantIds.toSet().toList();
    final shares = _buildEqualShares(roundBankers(amount), sanitizedParticipants);
    return GroupExpense(
      id: _generateId('exp'),
      title: title,
      amount: roundBankers(amount),
      currency: baseCurrency,
      amountBase: roundBankers(amount),
      paidBy: paidBy,
      participantIds: sanitizedParticipants,
      shares: shares,
      category: category,
      createdAt: createdAt,
      notes: notes,
    );
  }

  List<ExpenseShare> _buildEqualShares(double amount, List<String> participantIds) {
    if (participantIds.isEmpty) {
      return const [];
    }
    final count = participantIds.length;
    final baseShare = roundBankers(amount / count);
    final shares = <ExpenseShare>[];
    var allocated = 0.0;
    for (var index = 0; index < count; index++) {
      var share = baseShare;
      if (index == count - 1) {
        share = roundBankers(amount - allocated);
      }
      allocated = roundBankers(allocated + share);
      shares.add(ExpenseShare(memberId: participantIds[index], shareAmount: share));
    }
    return shares;
  }

  String _nameForMember(GroupDetail group, String memberId) {
    return group.memberById(memberId)?.displayName ?? 'Unknown member';
  }

  String _nameForMemberRaw(List<GroupMember> members, String memberId) {
    for (final member in members) {
      if (member.id == memberId) {
        return member.displayName;
      }
    }
    return 'Unknown member';
  }

  String _generateId(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_groups.length + _memberDirectory.length}';
}
