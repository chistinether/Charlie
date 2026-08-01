import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/test_users.dart';
import '../models/user_budget.dart';
import '../models/budget_item.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // ---------- SIGN UP ----------

  static Future<TestUser> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String university,
    required String course,
    required int year,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    final userData = {
      "name": name,
      "email": email,
      "phone": phone,
      "university": university,
      "course": course,
      "year": year,
      "balance": 0.0,
      "income": 0.0,
      "expenses": 0.0,
    };

    await _db.child("users").child(uid).set(userData);

    return TestUser(
      name: name,
      email: email,
      password: password,
      phone: phone,
      university: university,
      course: course,
      year: year,
      balance: 0,
      income: 0,
      expenses: 0,
      transactions: [],
      budgetHistory: [],
    );
  }

  // ---------- LOGIN ----------

  static Future<TestUser> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    return await loadUser(uid);
  }

  // ---------- HELPERS ----------

  static BudgetItem _itemFromMap(String key, Map<String, dynamic> i) {
    return BudgetItem(
      id: i["id"] ?? key,
      name: i["name"] ?? "",
      category: i["category"] ?? "",
      quantity: (i["quantity"] as num?)?.toDouble() ?? 1,
      unit: i["unit"] ?? "item",
      unitCost: (i["unitCost"] as num?)?.toDouble() ?? 0,
      allocatedAmount: (i["allocatedAmount"] as num?)?.toDouble(),
      spentAmount: (i["spentAmount"] as num?)?.toDouble() ?? 0,
      isAI: i["isAI"] ?? false,
    );
  }

  static UserBudget _budgetFromMap(Map<String, dynamic> budgetData) {
    final items = <BudgetItem>[];

    if (budgetData["items"] != null) {
      final itemsMap = Map<String, dynamic>.from(
        budgetData["items"] as Map,
      );

      itemsMap.forEach((key, value) {
        final i = Map<String, dynamic>.from(value as Map);
        items.add(_itemFromMap(key, i));
      });
    }

    return UserBudget(
      id: budgetData["id"] ?? "",
      purpose: budgetData["purpose"] ?? "",
      totalIncome: (budgetData["totalIncome"] as num?)?.toDouble() ?? 0,
      startDate:
          DateTime.tryParse(budgetData["startDate"] ?? "") ?? DateTime.now(),
      endDate:
          DateTime.tryParse(budgetData["endDate"] ?? "") ?? DateTime.now(),
      isAI: budgetData["isAI"] ?? false,
      items: items,
    );
  }

  static Map<String, dynamic> _budgetToMap(UserBudget budget) {
    final itemsMap = <String, dynamic>{};

    for (var item in budget.items) {
      itemsMap[item.id] = {
        "id": item.id,
        "name": item.name,
        "category": item.category,
        "quantity": item.quantity,
        "unit": item.unit,
        "unitCost": item.unitCost,
        "allocatedAmount": item.allocatedAmount,
        "spentAmount": item.spentAmount,
        "isAI": item.isAI,
      };
    }

    return {
      "id": budget.id,
      "purpose": budget.purpose,
      "totalIncome": budget.totalIncome,
      "startDate": budget.startDate.toIso8601String(),
      "endDate": budget.endDate.toIso8601String(),
      "isAI": budget.isAI,
      "items": itemsMap,
    };
  }

  // ---------- LOAD FULL USER DATA FROM REALTIME DATABASE ----------

  static Future<TestUser> loadUser(String uid) async {
    final snapshot = await _db.child("users").child(uid).get();

    if (!snapshot.exists) {
      throw Exception("User data not found");
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    // ----- Transactions -----
    final transactions = <TransactionModel>[];

    if (data["transactions"] != null) {
      final transactionsMap = Map<String, dynamic>.from(
        data["transactions"] as Map,
      );

      transactionsMap.forEach((key, value) {
        final t = Map<String, dynamic>.from(value as Map);

        transactions.add(
          TransactionModel(
            title: t["title"] ?? "",
            category: t["category"] ?? "",
            amount: (t["amount"] as num?)?.toDouble() ?? 0,
            isIncome: t["isIncome"] ?? false,
            date: DateTime.tryParse(t["date"] ?? "") ?? DateTime.now(),
          ),
        );
      });

      transactions.sort((a, b) => a.date.compareTo(b.date));
    }

    // ----- Budget -----
    UserBudget? budget;

    if (data["budget"] != null) {
      budget = _budgetFromMap(
        Map<String, dynamic>.from(data["budget"] as Map),
      );
    }

    // ----- Budget history (for auto-fill / recycle) -----
    final budgetHistory = <UserBudget>[];

    if (data["budgetHistory"] != null) {
      final historyMap = Map<String, dynamic>.from(
        data["budgetHistory"] as Map,
      );

      final entries = historyMap.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      for (final entry in entries) {
        budgetHistory.add(
          _budgetFromMap(Map<String, dynamic>.from(entry.value as Map)),
        );
      }
    }

    return TestUser(
      name: data["name"] ?? "",
      email: data["email"] ?? "",
      password: "",
      phone: data["phone"] ?? "",
      university: data["university"] ?? "",
      course: data["course"] ?? "",
      year: data["year"] ?? 1,
      balance: (data["balance"] as num?)?.toDouble() ?? 0,
      income: (data["income"] as num?)?.toDouble() ?? 0,
      expenses: (data["expenses"] as num?)?.toDouble() ?? 0,
      transactions: transactions,
      budget: budget,
      budgetHistory: budgetHistory,
    );
  }

  // ---------- SAVE BUDGET ----------

  static Future<void> saveBudget(UserBudget budget) async {
    final uid = _auth.currentUser!.uid;

    await _db
        .child("users")
        .child(uid)
        .child("budget")
        .set(_budgetToMap(budget));
  }

  // ---------- ARCHIVE A BUDGET INTO HISTORY (for auto-fill / recycle) ----------

  static Future<void> archiveBudget(UserBudget budget) async {
    final uid = _auth.currentUser!.uid;

    await _db
        .child("users")
        .child(uid)
        .child("budgetHistory")
        .child(budget.id)
        .set(_budgetToMap(budget));
  }

  // ---------- ADD TRANSACTION ----------

  static Future<void> addTransaction(TransactionModel transaction) async {
    final uid = _auth.currentUser!.uid;

    final newRef = _db.child("users").child(uid).child("transactions").push();

    await newRef.set({
      "title": transaction.title,
      "category": transaction.category,
      "amount": transaction.amount,
      "isIncome": transaction.isIncome,
      "date": transaction.date.toIso8601String(),
    });

    final userRef = _db.child("users").child(uid);
    final snapshot = await userRef.get();
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    final currentBalance = (data["balance"] as num?)?.toDouble() ?? 0;
    final currentIncome = (data["income"] as num?)?.toDouble() ?? 0;
    final currentExpenses = (data["expenses"] as num?)?.toDouble() ?? 0;

    if (transaction.isIncome) {
      await userRef.update({
        "balance": currentBalance + transaction.amount,
        "income": currentIncome + transaction.amount,
      });
    } else {
      await userRef.update({
        "balance": currentBalance - transaction.amount,
        "expenses": currentExpenses + transaction.amount,
      });
    }
  }

  // ---------- SYNC RUNNING TOTALS (balance/income/expenses) ----------
  //
  // Use this after directly editing a budget item's spentAmount (e.g. from
  // the Excel-like budget table) so balance/expenses on the Home screen
  // and in Firebase stay correct without double counting via addTransaction.

  static Future<void> syncTotals({
    required double balance,
    required double income,
    required double expenses,
  }) async {
    final uid = _auth.currentUser!.uid;

    await _db.child("users").child(uid).update({
      "balance": balance,
      "income": income,
      "expenses": expenses,
    });
  }

  // ---------- LOGOUT ----------

  static Future<void> logout() async {
    await _auth.signOut();
  }

  static User? get currentUser => _auth.currentUser;
}
