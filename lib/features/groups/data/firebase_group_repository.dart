import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group_models.dart';
import 'group_repository.dart';

class FirebaseGroupRepository implements GroupRepository {
  FirebaseGroupRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  final _random = Random.secure();
  final Map<String, MemberProfile> _directoryCache = {};

  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _firestore.collection('groups');
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  String get currentUserId => _auth.currentUser?.uid ?? '';

  @override
  Future<GroupDataSnapshot> load() async {
    await _loadDirectory();
    final userId = currentUserId;
    QuerySnapshot<Map<String, dynamic>> groupsSnapshot;
    if (userId.isNotEmpty) {
      groupsSnapshot =
          await _groupsCollection.where('memberIds', arrayContains: userId).get();
    } else {
      groupsSnapshot = await _groupsCollection.get();
    }
    final groups = groupsSnapshot.docs
        .map((doc) => _mapGroup(doc.id, doc.data()))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    for (final group in groups) {
      _cacheDirectoryFromGroup(group);
    }
    return GroupDataSnapshot(
      groups: groups,
      directory: List<MemberProfile>.unmodifiable(_sortedDirectory()),
    );
  }

  @override
  MemberProfile ensureMember(String displayName) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Display name cannot be empty');
    }
    for (final entry in _directoryCache.entries) {
      if (entry.value.displayName.toLowerCase() == trimmed.toLowerCase()) {
        return entry.value;
      }
    }
    final docRef = _usersCollection.doc();
    final profile = MemberProfile(id: docRef.id, displayName: trimmed);
    _directoryCache[profile.id] = profile;
    unawaited(
      docRef.set({
        'displayName': trimmed,
        'createdAt': FieldValue.serverTimestamp(),
      }),
    );
    return profile;
  }

  @override
  Future<GroupDetail> createGroup({
    required String name,
    required String baseCurrency,
    required List<MemberProfile> members,
    String? note,
  }) async {
    final trimmedName = name.trim();
    if (members.length < 2) {
      throw StateError('Groups require at least two members');
    }
    final uniqueMembers = <String, MemberProfile>{};
    for (final member in members) {
      final ensured = ensureMember(member.displayName);
      uniqueMembers[ensured.id] = ensured;
    }
    if (!uniqueMembers.containsKey(currentUserId) && currentUserId.isNotEmpty) {
      final currentProfile = await _resolveCurrentUserProfile();
      uniqueMembers[currentProfile.id] = currentProfile;
    }
    final ordered = uniqueMembers.values.toList();
    if (ordered.length < 2) {
      throw StateError('Groups require at least two members');
    }
    final groupMembers = <GroupMember>[];
    for (var index = 0; index < ordered.length; index++) {
      final profile = ordered[index];
      groupMembers.add(
        GroupMember.fromProfile(
          profile,
          role: index == 0 ? GroupRole.admin : GroupRole.member,
        ),
      );
    }
    final now = DateTime.now();
    final history = <GroupHistoryEntry>[
      GroupHistoryEntry(
        id: _generateId('hist'),
        type: GroupHistoryType.groupCreated,
        title: '${trimmedName.isEmpty ? 'New group' : trimmedName} created',
        subtitle: '${groupMembers.length} members joined this space',
        timestamp: now,
      ),
      for (final member in groupMembers)
        GroupHistoryEntry(
          id: _generateId('hist'),
          type: GroupHistoryType.memberAdded,
          title: '${member.displayName} joined',
          subtitle:
              member.role == GroupRole.admin ? 'Appointed as admin' : 'Added as member',
          timestamp: now,
        ),
    ];
    final docRef = _groupsCollection.doc();
    final group = GroupDetail(
      id: docRef.id,
      name: trimmedName.isEmpty ? 'Untitled group' : trimmedName,
      baseCurrency: baseCurrency,
      members: groupMembers,
      expenses: const [],
      settlements: const [],
      history: history,
      simplifyDebts: true,
      defaultSplitStrategy: GroupDefaultSplitStrategy.paidByYouEqual,
      note: note?.trim().isEmpty ?? true ? null : note!.trim(),
    );
    await _writeGroup(docRef, group, createdAt: now);
    _cacheDirectoryFromGroup(group);
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
    return _mutateGroup(groupId, (group) {
      if (participantIds.isEmpty) {
        throw StateError('At least one participant is required');
      }
      if (!group.members.any((member) => member.id == paidBy)) {
        throw StateError('Payer must be a group member');
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
        category: category.trim().isEmpty ? 'General' : category.trim(),
        createdAt: now,
        notes: notes?.trim().isEmpty ?? true ? null : notes!.trim(),
      );
      final updatedExpenses = List<GroupExpense>.from(group.expenses)..add(expense);
      final subtitle =
          '${_nameForMember(group, paidBy)} paid ${group.baseCurrency} ${expense.amount.toStringAsFixed(2)}';
      final updatedHistory = List<GroupHistoryEntry>.from(group.history)
        ..add(
          GroupHistoryEntry(
            id: _generateId('hist'),
            type: GroupHistoryType.expenseAdded,
            title: '${expense.title} logged',
            subtitle: subtitle,
            timestamp: now,
          ),
        );
      return group.copyWith(expenses: updatedExpenses, history: updatedHistory);
    });
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
    return _mutateGroup(groupId, (group) {
      if (fromMemberId == toMemberId) {
        throw StateError('Cannot settle with the same member');
      }
      if (!group.members.any((member) => member.id == fromMemberId) ||
          !group.members.any((member) => member.id == toMemberId)) {
        throw StateError('Both members must be part of the group');
      }
      final now = recordedAt ?? DateTime.now();
      final settlement = GroupSettlement(
        id: _generateId('set'),
        fromMemberId: fromMemberId,
        toMemberId: toMemberId,
        amount: roundBankers(amount),
        method: method,
        recordedAt: now,
        reference: reference?.trim().isEmpty ?? true ? null : reference!.trim(),
      );
      final updatedSettlements = List<GroupSettlement>.from(group.settlements)
        ..add(settlement);
      final subtitle =
          '${_nameForMember(group, fromMemberId)} paid ${group.baseCurrency} ${settlement.amount.toStringAsFixed(2)} '
          'to ${_nameForMember(group, toMemberId)} via $method';
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
      return group.copyWith(settlements: updatedSettlements, history: updatedHistory);
    });
  }

  @override
  Future<GroupDetail> updateSimplifyDebts({
    required String groupId,
    required bool simplify,
  }) {
    return _mutateGroup(groupId, (group) {
      final now = DateTime.now();
      final updatedHistory = List<GroupHistoryEntry>.from(group.history)
        ..add(
          GroupHistoryEntry(
            id: _generateId('hist'),
            type: GroupHistoryType.note,
            title: simplify
                ? 'Simplify group debts enabled'
                : 'Simplify group debts disabled',
            subtitle: 'Updated by ${_nameForMember(group, currentUserId)}',
            timestamp: now,
          ),
        );
      return group.copyWith(simplifyDebts: simplify, history: updatedHistory);
    });
  }

  @override
  Future<GroupDetail> updateDefaultSplit({
    required String groupId,
    required GroupDefaultSplitStrategy strategy,
  }) {
    return _mutateGroup(groupId, (group) {
      final now = DateTime.now();
      final updatedHistory = List<GroupHistoryEntry>.from(group.history)
        ..add(
          GroupHistoryEntry(
            id: _generateId('hist'),
            type: GroupHistoryType.note,
            title: 'Default split updated',
            subtitle: '${strategy.title} • ${_nameForMember(group, currentUserId)}',
            timestamp: now,
          ),
        );
      return group.copyWith(defaultSplitStrategy: strategy, history: updatedHistory);
    });
  }

  @override
  Future<GroupDetail> addMember({
    required String groupId,
    required MemberProfile member,
    GroupRole role = GroupRole.member,
  }) async {
    return _mutateGroup(groupId, (group) {
      final ensured = ensureMember(member.displayName);
      if (group.members.any((existing) => existing.id == ensured.id)) {
        throw StateError('${ensured.displayName} is already in this group');
      }
      final newMember = GroupMember.fromProfile(ensured, role: role);
      final updatedMembers = List<GroupMember>.from(group.members)..add(newMember);
      final addedBy = _nameForMember(group, currentUserId);
      final history = List<GroupHistoryEntry>.from(group.history)
        ..add(
          GroupHistoryEntry(
            id: _generateId('hist'),
            type: GroupHistoryType.memberAdded,
            title: '${newMember.displayName} joined',
            subtitle:
                role == GroupRole.admin ? 'Appointed as admin' : 'Invited by $addedBy',
            timestamp: DateTime.now(),
          ),
        );
      final updated = group.copyWith(members: updatedMembers, history: history);
      _cacheDirectoryFromGroup(updated);
      return updated;
    });
  }

  @override
  Future<GroupDetail> removeMember({
    required String groupId,
    required String memberId,
  }) {
    return _mutateGroup(groupId, (group) {
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
      _cacheDirectoryFromGroup(updated);
      return updated;
    });
  }

  @override
  Future<GroupDetail> updateBaseCurrency({
    required String groupId,
    required String baseCurrency,
  }) {
    return _mutateGroup(groupId, (group) {
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
      return group.copyWith(
        baseCurrency: baseCurrency,
        expenses: updatedExpenses,
        history: history,
      );
    });
  }

  @override
  Future<GroupDetail?> leaveGroup({
    required String groupId,
    required String memberId,
  }) async {
    final docRef = _groupsCollection.doc(groupId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw StateError('Group not found');
    }
    final data = snapshot.data()!;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final group = _mapGroup(snapshot.id, data);
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
      await docRef.delete();
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
    await _writeGroup(docRef, updated, createdAt: createdAt ?? DateTime.now());
    _cacheDirectoryFromGroup(updated);
    return updated;
  }

  @override
  Future<void> deleteGroup({required String groupId}) async {
    await _groupsCollection.doc(groupId).delete();
  }

  Future<void> _loadDirectory() async {
    final snapshot = await _usersCollection.get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = (data['displayName'] as String?)?.trim() ??
          (data['name'] as String?)?.trim() ??
          '';
      if (name.isNotEmpty) {
        _directoryCache[doc.id] = MemberProfile(id: doc.id, displayName: name);
      }
    }
  }

  Future<MemberProfile> _resolveCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return ensureMember('You');
    }
    final existing = _directoryCache[user.uid];
    if (existing != null) {
      return existing;
    }
    final displayName = user.displayName?.trim();
    final profile = MemberProfile(
      id: user.uid,
      displayName: (displayName == null || displayName.isEmpty)
          ? 'You'
          : displayName,
    );
    _directoryCache[user.uid] = profile;
    await _usersCollection.doc(user.uid).set({
      'displayName': profile.displayName,
      'phoneNumber': user.phoneNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return profile;
  }

  Future<GroupDetail> _mutateGroup(
    String groupId,
    GroupDetail Function(GroupDetail) transform,
  ) async {
    final docRef = _groupsCollection.doc(groupId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw StateError('Group not found');
    }
    final data = snapshot.data()!;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final current = _mapGroup(snapshot.id, data);
    final updated = transform(current);
    await _writeGroup(docRef, updated, createdAt: createdAt ?? DateTime.now());
    _cacheDirectoryFromGroup(updated);
    return updated;
  }

  GroupDetail _mapGroup(String id, Map<String, dynamic> data) {
    final membersData = (data['members'] as List?) ?? const [];
    final members = membersData
        .whereType<Map<String, dynamic>>()
        .map(
          (entry) => GroupMember(
            id: (entry['id'] as String? ?? '').trim(),
            displayName: (entry['displayName'] as String? ?? '').trim(),
            role: _parseRole(entry['role'] as String?),
          ),
        )
        .where((member) => member.id.isNotEmpty)
        .toList();

    final expenses = ((data['expenses'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (entry) => GroupExpense(
            id: (entry['id'] as String? ?? '').isEmpty
                ? _generateId('exp')
                : entry['id'] as String,
            title: (entry['title'] as String? ?? '').trim(),
            amount: (entry['amount'] as num?)?.toDouble() ?? 0,
            currency: (entry['currency'] as String? ?? data['baseCurrency'] as String? ?? 'INR')
                .trim(),
            amountBase: (entry['amountBase'] as num?)?.toDouble() ??
                (entry['amount'] as num?)?.toDouble() ??
                0,
            paidBy: (entry['paidBy'] as String? ?? '').trim(),
            participantIds: ((entry['participantIds'] as List?) ?? const [])
                .whereType<String>()
                .toList(),
            shares: ((entry['shares'] as List?) ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(
                  (share) => ExpenseShare(
                    memberId: (share['memberId'] as String? ?? '').trim(),
                    shareAmount: (share['shareAmount'] as num?)?.toDouble() ?? 0,
                  ),
                )
                .where((share) => share.memberId.isNotEmpty)
                .toList(),
            category: (entry['category'] as String? ?? 'General').trim(),
            createdAt:
                (entry['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            notes: (entry['notes'] as String?)?.trim().isEmpty ?? true
                ? null
                : (entry['notes'] as String).trim(),
          ),
        )
        .toList();

    final settlements = ((data['settlements'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (entry) => GroupSettlement(
            id: (entry['id'] as String? ?? '').isEmpty
                ? _generateId('set')
                : entry['id'] as String,
            fromMemberId: (entry['fromMemberId'] as String? ?? '').trim(),
            toMemberId: (entry['toMemberId'] as String? ?? '').trim(),
            amount: (entry['amount'] as num?)?.toDouble() ?? 0,
            method: (entry['method'] as String? ?? '').trim(),
            recordedAt:
                (entry['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            reference: (entry['reference'] as String?)?.trim().isEmpty ?? true
                ? null
                : (entry['reference'] as String).trim(),
          ),
        )
        .toList();

    final history = ((data['history'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (entry) => GroupHistoryEntry(
            id: (entry['id'] as String? ?? '').isEmpty
                ? _generateId('hist')
                : entry['id'] as String,
            type: _parseHistoryType(entry['type'] as String?),
            title: (entry['title'] as String? ?? '').trim(),
            subtitle: (entry['subtitle'] as String? ?? '').trim(),
            timestamp:
                (entry['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ),
        )
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return GroupDetail(
      id: id,
      name: (data['name'] as String? ?? 'Untitled group').trim(),
      baseCurrency: (data['baseCurrency'] as String? ?? 'INR').trim(),
      members: members,
      expenses: expenses,
      settlements: settlements,
      history: history,
      simplifyDebts: data['simplifyDebts'] as bool? ?? true,
      defaultSplitStrategy:
          _parseDefaultStrategy(data['defaultSplitStrategy'] as String?),
      note: (data['note'] as String?)?.trim().isEmpty ?? true
          ? null
          : (data['note'] as String).trim(),
    );
  }

  Future<void> _writeGroup(
    DocumentReference<Map<String, dynamic>> ref,
    GroupDetail group, {
    required DateTime createdAt,
  }) async {
    final data = _serializeGroup(group)
      ..addAll({
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    await ref.set(data);
  }

  Map<String, dynamic> _serializeGroup(GroupDetail group) {
    return {
      'name': group.name,
      'baseCurrency': group.baseCurrency,
      'note': group.note,
      'simplifyDebts': group.simplifyDebts,
      'defaultSplitStrategy': group.defaultSplitStrategy.name,
      'members': [
        for (final member in group.members)
          {
            'id': member.id,
            'displayName': member.displayName,
            'role': member.role.name,
          }
      ],
      'memberIds': [for (final member in group.members) member.id],
      'expenses': [
        for (final expense in group.expenses)
          {
            'id': expense.id,
            'title': expense.title,
            'amount': expense.amount,
            'currency': expense.currency,
            'amountBase': expense.amountBase,
            'paidBy': expense.paidBy,
            'participantIds': expense.participantIds,
            'shares': [
              for (final share in expense.shares)
                {
                  'memberId': share.memberId,
                  'shareAmount': share.shareAmount,
                }
            ],
            'category': expense.category,
            'createdAt': Timestamp.fromDate(expense.createdAt),
            'notes': expense.notes,
          }
      ],
      'settlements': [
        for (final settlement in group.settlements)
          {
            'id': settlement.id,
            'fromMemberId': settlement.fromMemberId,
            'toMemberId': settlement.toMemberId,
            'amount': settlement.amount,
            'method': settlement.method,
            'recordedAt': Timestamp.fromDate(settlement.recordedAt),
            'reference': settlement.reference,
          }
      ],
      'history': [
        for (final entry in group.history)
          {
            'id': entry.id,
            'type': entry.type.name,
            'title': entry.title,
            'subtitle': entry.subtitle,
            'timestamp': Timestamp.fromDate(entry.timestamp),
          }
      ],
    };
  }

  GroupRole _parseRole(String? raw) {
    return GroupRole.values.firstWhere(
      (role) => role.name == raw,
      orElse: () => GroupRole.member,
    );
  }

  GroupHistoryType _parseHistoryType(String? raw) {
    return GroupHistoryType.values.firstWhere(
      (type) => type.name == raw,
      orElse: () => GroupHistoryType.note,
    );
  }

  GroupDefaultSplitStrategy _parseDefaultStrategy(String? raw) {
    return GroupDefaultSplitStrategy.values.firstWhere(
      (strategy) => strategy.name == raw,
      orElse: () => GroupDefaultSplitStrategy.paidByYouEqual,
    );
  }

  List<MemberProfile> _sortedDirectory() {
    final list = _directoryCache.values.toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return list;
  }

  void _cacheDirectoryFromGroup(GroupDetail group) {
    for (final member in group.members) {
      _directoryCache[member.id] =
          MemberProfile(id: member.id, displayName: member.displayName);
    }
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
    if (memberId.isEmpty) {
      return 'Unknown member';
    }
    return group.memberById(memberId)?.displayName ??
        _directoryCache[memberId]?.displayName ??
        'Unknown member';
  }

  String _generateId(String prefix) {
    final randomPart = _random.nextInt(0x7fffffff);
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$randomPart';
  }
}
